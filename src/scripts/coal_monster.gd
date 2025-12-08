extends CharacterBody2D

var health = 10.0
var speed = 50.0
var damage = 1.0

var knockback_force: Vector2 = Vector2.ZERO
var knockback_timer = 0.0
var knockback_duration = 0.05

var attack_range = 20.0
var attack_cooldown = 1.0
var attack_timer = 0.0

var dash_speed = 200.0
var dash_duration = 0.2
var dash_timer = 0.0
var is_dead = false
var _death_timer = null
var _anim_finished_connected := false
var _freeing = false

@onready var anim = $AnimatedSprite2D
@onready var anima_player = $AnimatedSprite2D/AnimationPlayer

func _ready():
	anim.play("run")

func _physics_process(delta: float) -> void:
	if dash_timer > 0:
		dash_timer -= delta
		move_and_slide()
		return
	
	if knockback_timer > 0:
		handle_knockback(delta)
		knockback_force.move_toward(Vector2.ZERO, delta)
	else:
		if Global.player:
			var distance = global_position.distance_to(Global.player.global_position)
			
			if distance <= attack_range and attack_timer <= 0:
				dash_to_player()
				attack_timer = attack_cooldown
			else:
				chase_player()
				
			attack_timer -= delta
	move_and_slide()

func handle_knockback(delta: float):
	if knockback_timer > 0:
		velocity = knockback_force
		knockback_timer -= delta

func get_damaged(amount: float):
	# Ignore further damage if already dead (prevents repeated drops)
	if is_dead:
		return

	anima_player.play("hit")
	knockback_timer = knockback_duration
	health -= amount

	if health <= 0.0:
		# Mark dead early to prevent re-entry
		is_dead = true

		# Stop movement/AI
		velocity = Vector2.ZERO
		dash_timer = 0.0
		knockback_timer = 0.0
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
		var dir = Vector2(Global.player.global_position - global_position)
		var distance = global_position.distance_to(Global.player.global_position)
		
		if distance >= attack_range:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2(randf_range(-2, 2), randf_range(-2, 2))

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
