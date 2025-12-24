extends CharacterBody2D

var health = 12.0
var speed = 50.0
var chase_speed = 60.0  # Tốc độ khi truy đuổi
var damage = 2.0

var knockback_force: Vector2 = Vector2.ZERO
var knockback_timer = 0.0
var knockback_duration = 0.05

# Contact damage cooldown
var damage_cooldown = 1.0  # 1 giây cooldown
var damage_timer = 0.0

# Detection and attack ranges
var detection_range = 80.0  # Khoảng cách phát hiện player
var attack_range = 30.0     # Khoảng cách tấn công (contact damage)

# Random movement
var wander_timer = 0.0
var wander_duration = 2.0  # Thời gian di chuyển ngẫu nhiên
var wander_direction = Vector2.ZERO

# States
enum State { WANDERING, CHASING }
var current_state = State.WANDERING

var is_dead = false
var _death_timer = null
var _anim_finished_connected := false
var _freeing = false

@onready var anim = $AnimatedSprite2D
@onready var anima_player = $AnimatedSprite2D/AnimationPlayer

func _ready():
	anim.play("run")
	
	# Setup hit flash shader
	setup_hit_flash()
	
	# Check if Area2D exists
	if has_node("Area2D"):
		print("[Golem] Area2D found - contact damage enabled")
	else:
		print("[Golem] WARNING: Area2D not found - contact damage disabled!")

func setup_hit_flash():
	"""Setup hit flash shader cho sprite"""
	if anim and anim.material == null:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shader/hit_flash.gdshader")
		anim.material = shader_material

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Handle knockback first
	if knockback_timer > 0:
		handle_knockback(delta)
		knockback_force.move_toward(Vector2.ZERO, delta)
		move_and_slide()
		return
	
	# Update timers
	wander_timer -= delta
	damage_timer -= delta
	
	# State machine
	update_ai_state(delta)
	move_and_slide()
	
	# Check for contact damage (fallback if Area2D doesn't work)
	check_contact_damage()

func handle_knockback(delta: float):
	if knockback_timer > 0:
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

func handle_wandering_state(distance_to_player: float):
	if distance_to_player <= detection_range:
		# Player vào tầm phát hiện, chuyển sang truy đuổi
		current_state = State.CHASING
		print("[Golem] Player detected! Switching to CHASING")
	else:
		# Di chuyển ngẫu nhiên
		wander_randomly()

func handle_chasing_state(distance_to_player: float):
	if distance_to_player > detection_range * 1.2:  # Thêm hysteresis để tránh flicker
		# Player ra khỏi tầm phát hiện, quay về wandering
		current_state = State.WANDERING
		print("[Golem] Lost player! Switching to WANDERING")
	else:
		# Tiếp tục truy đuổi với tốc độ cao
		chase_player()

func wander_randomly():
	if wander_timer <= 0:
		# Tạo hướng di chuyển ngẫu nhiên mới
		var angle = randf() * TAU  # TAU = 2 * PI
		wander_direction = Vector2(cos(angle), sin(angle))
		wander_timer = wander_duration
	
	velocity = wander_direction * speed * 0.3  # Di chuyển chậm hơn khi wander

func chase_player():
	if Global.player:
		var dir = (Global.player.global_position - global_position).normalized()
		velocity = dir * chase_speed  # Sử dụng tốc độ truy đuổi cao hơn

func get_damaged(amount: float):
	# Ignore further damage if already dead (prevents repeated drops)
	if is_dead:
		return

	# Play hit sound
	AudioManager.play_sfx("hit")
	
	# Play hit flash effect
	play_hit_flash()
	
	# Play hit animation if available
	if anima_player:
		anima_player.play("hit")
	
	knockback_timer = knockback_duration
	health -= amount

	if health <= 0.0:
		# Mark dead early to prevent re-entry
		is_dead = true

		# Stop movement/AI completely
		velocity = Vector2.ZERO
		knockback_timer = 0.0
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

func drop_loot():
	# Random drop: 25% drop 3 than đá
	var drop_chance = randf()
	
	if drop_chance < 0.25:
		# 25% drop 3 than đá
		var items_texture = preload("res://assets/sprites/items.png")
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = items_texture
		atlas_texture.region = Rect2(24, 0, 24, 24)  # Region của than đá
		
		var item_to_drop = {
			"item_type": "Vật liệu",
			"item_name": "Than đá",
			"item_texture": atlas_texture,
			"item_effect": "",
			"quantity": 3
		}
		
		Global.drop_item(item_to_drop, global_position, get_parent())

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.player.take_damaged(damage)

func check_contact_damage():
	"""Kiểm tra va chạm trực tiếp với player (fallback nếu Area2D không hoạt động)"""
	if Global.player and not is_dead and damage_timer <= 0:
		var distance = global_position.distance_to(Global.player.global_position)
		if distance < 25.0:  # Khoảng cách va chạm
			Global.player.take_damaged(damage)
			damage_timer = damage_cooldown  # Reset cooldown
			print("[Golem] Contact damage to player: ", damage)
			# Knockback player
			var knockback_dir = (Global.player.global_position - global_position).normalized()
			Global.player.velocity += knockback_dir * 200  # Đẩy player ra xa

func _on_anim_finished() -> void:
	# Called either from AnimatedSprite2D.animation_finished or fallback timer
	if not is_inside_tree():
		return
	# Avoid double-handling if multiple signals fire (timer + animation)
	if _freeing:
		return
	_freeing = true
	# Disconnect signals and stop fallback timer
	if _anim_finished_connected and anim.is_connected("animation_finished", Callable(self, "_on_anim_finished")):
		anim.disconnect("animation_finished", Callable(self, "_on_anim_finished"))
		_anim_finished_connected = false
	if _death_timer != null and _death_timer.is_connected("timeout", Callable(self, "_on_anim_finished")):
		_death_timer.stop()
		_death_timer.queue_free()
		_death_timer = null

	# final cleanup
	queue_free()
func play_hit_flash():
	"""Phát hiệu ứng hit flash"""
	if anim and anim.material:
		# Bật hit flash
		anim.material.set_shader_parameter("hit_flash_on", true)
		anim.material.set_shader_parameter("hit_flash_color", Color.WHITE)
		
		# Tắt sau 0.1 giây
		await get_tree().create_timer(0.1).timeout
		if anim and anim.material:
			anim.material.set_shader_parameter("hit_flash_on", false)
