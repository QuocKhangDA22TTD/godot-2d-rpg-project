extends CharacterBody2D

var health = 10.0
var speed = 50.0
var damage = 5.0

var knockback_force: Vector2 = Vector2.ZERO
var knockback_timer = 0.0
var knockback_duration = 0.05

# Detection and attack ranges
var detection_range = 80.0  # Khoảng cách phát hiện player
var attack_range = 30.0     # Khoảng cách tấn công
var attack_cooldown = 2.0   # Thời gian hồi chiêu
var attack_timer = 0.0

# Attack preparation
var prepare_attack_time = 0.5  # Thời gian chuẩn bị trước khi lao vào
var prepare_timer = 0.0
var is_preparing_attack = false

# Dash attack
var dash_speed = 200.0
var dash_duration = 0.2
var dash_timer = 0.0

# Random movement
var wander_timer = 0.0
var wander_duration = 2.0  # Thời gian di chuyển ngẫu nhiên
var wander_direction = Vector2.ZERO

# States
enum State { WANDERING, CHASING, PREPARING_ATTACK, ATTACKING }
var current_state = State.WANDERING

var is_dead = false
var _death_timer = null
var _anim_finished_connected := false
var _freeing = false

@onready var anim = $AnimatedSprite2D
@onready var anima_player = $AnimatedSprite2D/AnimationPlayer

func _ready():
	anim.play("run")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Handle knockback first
	if knockback_timer > 0:
		handle_knockback(delta)
		knockback_force.move_toward(Vector2.ZERO, delta)
		move_and_slide()
		return
	
	# Handle dash attack
	if dash_timer > 0:
		dash_timer -= delta
		# Chỉ di chuyển nếu không bị knockback
		if knockback_timer <= 0:
			move_and_slide()
		if dash_timer <= 0:
			current_state = State.CHASING  # Chuyển về chasing thay vì wandering
			attack_timer = attack_cooldown
		return
	
	# Update timers
	attack_timer -= delta
	wander_timer -= delta
	prepare_timer -= delta
	
	# State machine
	update_ai_state(delta)
	move_and_slide()

func handle_knockback(delta: float):
	if knockback_timer > 0:
		# Knockback có ưu tiên cao hơn dash
		if dash_timer > 0:
			dash_timer = 0.0  # Hủy dash khi bị knockback
		velocity = knockback_force
		knockback_timer -= delta

func update_ai_state(delta: float):
	if not Global.player:
		wander_randomly()
		return
	
	var distance_to_player = global_position.distance_to(Global.player.global_position)
	
	match current_state:
		State.WANDERING:
			handle_wandering_state(distance_to_player)
		
		State.CHASING:
			handle_chasing_state(distance_to_player)
		
		State.PREPARING_ATTACK:
			handle_preparing_attack_state(distance_to_player)
		
		State.ATTACKING:
			# Đang trong trạng thái dash, không cần xử lý gì thêm
			pass

func handle_wandering_state(distance_to_player: float):
	if distance_to_player <= detection_range:
		# Player vào tầm phát hiện, chuyển sang truy đuổi
		current_state = State.CHASING
		print("[CoalMonster] Player detected! Switching to CHASING")
	else:
		# Di chuyển ngẫu nhiên
		wander_randomly()

func handle_chasing_state(distance_to_player: float):
	if distance_to_player > detection_range * 1.2:  # Thêm hysteresis để tránh flicker
		# Player ra khỏi tầm phát hiện, quay về wandering
		current_state = State.WANDERING
		print("[CoalMonster] Lost player! Switching to WANDERING")
	elif distance_to_player <= attack_range and attack_timer <= 0:
		# Vào tầm tấn công, bắt đầu chuẩn bị
		current_state = State.PREPARING_ATTACK
		prepare_timer = prepare_attack_time
		velocity = Vector2.ZERO  # Dừng lại để chuẩ bị
		print("[CoalMonster] In attack range! Preparing attack...")
	else:
		# Tiếp tục truy đuổi
		chase_player()

func handle_preparing_attack_state(distance_to_player: float):
	if distance_to_player > attack_range * 1.5:
		# Player thoát khỏi tầm tấn công, quay về truy đuổi
		current_state = State.CHASING
		is_preparing_attack = false
		print("[CoalMonster] Player escaped! Back to CHASING")
	elif prepare_timer <= 0:
		# Hết thời gian chuẩn bị, thực hiện tấn công
		current_state = State.ATTACKING
		dash_to_player()
		print("[CoalMonster] ATTACK!")
	else:
		# Đang chuẩn bị tấn công - đứng yên và có thể thêm hiệu ứng
		velocity = Vector2.ZERO
		# Có thể thêm animation chuẩn bị ở đây

func wander_randomly():
	if wander_timer <= 0:
		# Tạo hướng di chuyển ngẫu nhiên mới
		var angle = randf() * TAU  # TAU = 2 * PI
		wander_direction = Vector2(cos(angle), sin(angle))
		wander_timer = wander_duration
	
	velocity = wander_direction * speed * 0.3  # Di chuyển chậm hơn khi wander

func get_damaged(amount: float):
	# Ignore further damage if already dead (prevents repeated drops)
	if is_dead:
		return

	# Reset state khi bị tấn công để tránh xung đột
	if current_state == State.PREPARING_ATTACK or current_state == State.ATTACKING:
		# Hủy bỏ tấn công hiện tại
		prepare_timer = 0.0
		dash_timer = 0.0
		is_preparing_attack = false
		# Chuyển về trạng thái truy đuổi sau khi bị knockback
		current_state = State.CHASING
		attack_timer = attack_cooldown * 0.5  # Giảm thời gian hồi chiêu một chút
		print("[CoalMonster] Attack interrupted by damage!")

	anima_player.play("hit")
	knockback_timer = knockback_duration
	health -= amount

	if health <= 0.0:
		# Mark dead early to prevent re-entry
		is_dead = true

		# Stop movement/AI completely
		velocity = Vector2.ZERO
		dash_timer = 0.0
		knockback_timer = 0.0
		prepare_timer = 0.0
		current_state = State.WANDERING  # Reset state
		set_physics_process(false)

		# Disable collisions/interactions so it can't attack or be hit
		collision_layer = 0
		collision_mask = 0
		if has_node("Area2D"):
			$Area2D.monitoring = false

		# Spawn loot once
		drop_loot()

		# Play death animation and wait for animation_finished (with fallback timer)
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("dead"):
			# Connect to animation_finished once
			if not _anim_finished_connected:
				if anim.is_connected("animation_finished", Callable(self, "_on_anim_finished")):
					anim.disconnect("animation_finished", Callable(self, "_on_anim_finished"))
				anim.connect("animation_finished", Callable(self, "_on_anim_finished"))
				_anim_finished_connected = true
			anim.play("dead")
			# Fallback timer: free after 1.0s if animation_finished signal doesn't fire
			if _death_timer == null:
				_death_timer = Timer.new()
				_death_timer.one_shot = true
				_death_timer.wait_time = 1.0
				add_child(_death_timer)
				_death_timer.start()
				_death_timer.connect("timeout", Callable(self, "_on_anim_finished"))
		else:
			# fallback: no sprite frames available, free immediately
			queue_free()

func chase_player():
	if Global.player:
		var dir = (Global.player.global_position - global_position).normalized()
		velocity = dir * speed

func dash_to_player():
	var dir = (Global.player.global_position - global_position).normalized()
	velocity = dir * dash_speed
	dash_timer = dash_duration

func drop_loot():
	# Random drop: 70% than đá, 30% bình máu
	var drop_chance = randf()
	var item_to_drop = {}
	
	# Tạo AtlasTexture cho items.png
	var items_texture = preload("res://assets/sprites/items.png")
	
	if drop_chance < 0.7:
		# 70% drop than đá
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = items_texture
		atlas_texture.region = Rect2(24, 0, 24, 24)  # Region của than đá
		
		item_to_drop = {
			"item_type": "Vật liệu",
			"item_name": "Than đá",
			"item_texture": atlas_texture,
			"item_effect": "",
			"quantity": 1
		}
		# drop than
	else:
		# 30% drop bình máu
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = items_texture
		atlas_texture.region = Rect2(0, 0, 24, 24)  # Region của bình máu
		
		item_to_drop = {
			"item_type": "Tiêu hao",
			"item_name": "Bình máu",
			"item_texture": atlas_texture,
			"item_effect": "heal",
			"quantity": 1
		}
		# drop heal
	
	Global.drop_item(item_to_drop, global_position, get_parent())

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.player.take_damaged(damage)

func _on_anim_finished() -> void:
	# Called either from AnimatedSprite2D.animation_finished or fallback timer
	if not is_inside_tree():
		return
	# Avoid double-handling if multiple signals fire (timer + animation)
	if _freeing:
		return
	_freeing = true
	# Disconnect signals and stop fallback timer
	# frame_changed handler removed in simplified flow
	if _anim_finished_connected and anim.is_connected("animation_finished", Callable(self, "_on_anim_finished")):
		anim.disconnect("animation_finished", Callable(self, "_on_anim_finished"))
		_anim_finished_connected = false
	if _death_timer != null and _death_timer.is_connected("timeout", Callable(self, "_on_anim_finished")):
		_death_timer.stop()
		_death_timer.queue_free()
		_death_timer = null

	# final cleanup
	queue_free()
