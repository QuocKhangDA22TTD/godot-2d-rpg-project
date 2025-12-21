extends CharacterBody2D

# Basic stats
var max_health = 80.0
var health = 80.0
var base_speed = 25.0
var contact_damage = 4.0
var armor_reduction = 0.25  # Giảm 25% damage

# Movement and detection
var detection_radius = 120.0
var attack_radius = 50.0
var player_target = null
var move_speed = 0.0

# Attack system
var slam_cooldown = 4.0
var slam_timer = 0.0
var slam_charge_time = 1.5
var slam_damage = 8.0
var slam_range = 70.0

# State management
enum GolemState { IDLE, PATROL, CHASE, CHARGE_ATTACK, SLAM, STUNNED }
var current_state = GolemState.IDLE
var state_timer = 0.0

# Patrol behavior
var patrol_points = []
var current_patrol_target = 0
var patrol_wait_time = 2.0

# Knockback
var knockback_velocity = Vector2.ZERO
var knockback_force = Vector2.ZERO  # Để tương thích với attack_hitbox.gd
var knockback_decay = 800.0

# Animation and visuals
var sprite_node = null
var animation_player = null
var is_dead = false

func _ready():
	# Safely get animation nodes
	if has_node("AnimatedSprite2D"):
		sprite_node = $AnimatedSprite2D
	if has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	
	# Setup patrol points around spawn
	setup_patrol_points()
	
	# Add to enemy group
	add_to_group("Enemy")
	
	# Start in idle state
	change_state(GolemState.IDLE)
	
	print("[Golem] Initialized with health: ", health)

func setup_patrol_points():
	"""Tạo các điểm tuần tra xung quanh vị trí spawn"""
	var spawn_pos = global_position
	patrol_points = [
		spawn_pos + Vector2(60, 0),
		spawn_pos + Vector2(0, 60),
		spawn_pos + Vector2(-60, 0),
		spawn_pos + Vector2(0, -60),
		spawn_pos  # Quay về điểm gốc
	]

func _physics_process(delta):
	if is_dead:
		return
	
	# Update timers
	state_timer += delta
	slam_timer -= delta
	
	# Handle knockback
	if knockback_velocity.length() > 0 or knockback_force.length() > 0:
		# Sử dụng knockback_force nếu có (từ attack_hitbox), nếu không dùng knockback_velocity
		if knockback_force.length() > 0:
			velocity = knockback_force
			knockback_force = knockback_force.move_toward(Vector2.ZERO, knockback_decay * delta)
		else:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		# Normal movement
		update_state_behavior(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update sprite direction
	update_sprite_direction()

func update_state_behavior(delta):
	"""Cập nhật hành vi theo state hiện tại"""
	match current_state:
		GolemState.IDLE:
			handle_idle_state()
		
		GolemState.PATROL:
			handle_patrol_state()
		
		GolemState.CHASE:
			handle_chase_state()
		
		GolemState.CHARGE_ATTACK:
			handle_charge_attack_state()
		
		GolemState.SLAM:
			handle_slam_state()
		
		GolemState.STUNNED:
			handle_stunned_state()

func handle_idle_state():
	"""Trạng thái đứng yên, quan sát"""
	velocity = Vector2.ZERO
	
	# Tìm player
	find_player()
	
	if player_target and is_player_in_detection_range():
		change_state(GolemState.CHASE)
	elif state_timer > patrol_wait_time:
		change_state(GolemState.PATROL)

func handle_patrol_state():
	"""Tuần tra giữa các điểm"""
	if patrol_points.size() == 0:
		change_state(GolemState.IDLE)
		return
	
	var target_point = patrol_points[current_patrol_target]
	var direction = (target_point - global_position).normalized()
	
	velocity = direction * base_speed * 0.6  # Chậm khi patrol
	
	# Kiểm tra đã đến điểm chưa
	if global_position.distance_to(target_point) < 20:
		current_patrol_target = (current_patrol_target + 1) % patrol_points.size()
		change_state(GolemState.IDLE)
	
	# Tìm player trong lúc patrol
	find_player()
	if player_target and is_player_in_detection_range():
		change_state(GolemState.CHASE)

func handle_chase_state():
	"""Truy đuổi player"""
	if not player_target or not is_instance_valid(player_target):
		change_state(GolemState.IDLE)
		return
	
	var distance = global_position.distance_to(player_target.global_position)
	
	# Mất player
	if distance > detection_radius * 1.2:
		player_target = null
		change_state(GolemState.PATROL)
		return
	
	# Trong tầm tấn công
	if distance <= attack_radius and slam_timer <= 0:
		change_state(GolemState.CHARGE_ATTACK)
		return
	
	# Di chuyển về phía player
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * base_speed

func handle_charge_attack_state():
	"""Chuẩn bị tấn công slam"""
	velocity = Vector2.ZERO  # Đứng yên khi charge
	
	if state_timer >= slam_charge_time:
		execute_slam_attack()
		change_state(GolemState.SLAM)

func handle_slam_state():
	"""Thực hiện slam attack"""
	velocity = Vector2.ZERO
	
	if state_timer >= 0.8:  # Thời gian slam
		slam_timer = slam_cooldown
		change_state(GolemState.STUNNED)

func handle_stunned_state():
	"""Bị choáng sau khi slam"""
	velocity = Vector2.ZERO
	
	if state_timer >= 1.0:  # Thời gian choáng
		change_state(GolemState.CHASE)

func execute_slam_attack():
	"""Thực hiện đòn slam và gây damage"""
	print("[Golem] Executing slam attack!")
	
	if player_target and is_instance_valid(player_target):
		var distance = global_position.distance_to(player_target.global_position)
		
		if distance <= slam_range:
			# Gây damage cho player
			if player_target.has_method("take_damaged"):
				player_target.take_damaged(slam_damage)
			
			# Knockback player
			var knockback_dir = (player_target.global_position - global_position).normalized()
			if player_target.has_method("apply_knockback"):
				player_target.apply_knockback(knockback_dir * 400)
			
			print("[Golem] Slam hit player for ", slam_damage, " damage!")

func find_player():
	"""Tìm player trong game"""
	if Global.player and is_instance_valid(Global.player):
		player_target = Global.player

func is_player_in_detection_range() -> bool:
	"""Kiểm tra player có trong tầm phát hiện không"""
	if not player_target:
		return false
	
	return global_position.distance_to(player_target.global_position) <= detection_radius

func change_state(new_state: GolemState):
	"""Thay đổi state và reset timer"""
	current_state = new_state
	state_timer = 0.0
	
	# Update animation based on state
	update_animation_for_state(new_state)
	
	print("[Golem] State changed to: ", GolemState.keys()[new_state])

func update_animation_for_state(state: GolemState):
	"""Cập nhật animation theo state"""
	if not sprite_node:
		return
	
	match state:
		GolemState.IDLE, GolemState.STUNNED:
			play_animation("idle")
		
		GolemState.PATROL, GolemState.CHASE:
			play_animation("run")
		
		GolemState.CHARGE_ATTACK:
			play_animation("idle")  # Có thể thay bằng "charge" nếu có
		
		GolemState.SLAM:
			play_animation("idle")  # Có thể thay bằng "attack" nếu có

func play_animation(anim_name: String):
	"""Safely play animation"""
	if sprite_node and sprite_node.has_method("play"):
		if sprite_node.sprite_frames and sprite_node.sprite_frames.has_animation(anim_name):
			sprite_node.play(anim_name)

func update_sprite_direction():
	"""Cập nhật hướng sprite theo movement"""
	if not sprite_node:
		return
	
	if velocity.x < -5:
		sprite_node.flip_h = true
	elif velocity.x > 5:
		sprite_node.flip_h = false

func get_damaged(damage_amount: float):
	"""Nhận damage với armor reduction"""
	if is_dead:
		return
	
	# Áp dụng armor
	var actual_damage = damage_amount * (1.0 - armor_reduction)
	health -= actual_damage
	
	print("[Golem] Took ", actual_damage, " damage. Health: ", health, "/", max_health)
	
	# Interrupt attack nếu đang charge
	if current_state == GolemState.CHARGE_ATTACK:
		change_state(GolemState.CHASE)
		slam_timer = slam_cooldown * 0.3  # Giảm cooldown một chút
	
	# Play hit animation
	if animation_player and animation_player.has_method("play"):
		animation_player.play("hit")
	
	# Knockback
	if player_target:
		var knockback_dir = (global_position - player_target.global_position).normalized()
		knockback_velocity = knockback_dir * 150
		knockback_force = Vector2.ZERO  # Reset knockback_force
	
	# Check death
	if health <= 0:
		die()

func die():
	"""Xử lý khi golem chết"""
	if is_dead:
		return
	
	is_dead = true
	print("[Golem] Died!")
	
	# Stop all movement
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_force = Vector2.ZERO
	
	# Disable physics
	set_physics_process(false)
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Drop loot
	drop_valuable_loot()
	
	# Play death animation and cleanup
	play_animation("idle")  # Fallback animation
	
	# Auto cleanup after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func drop_valuable_loot():
	"""Drop loot có giá trị cao"""
	var items_texture = preload("res://assets/sprites/items.png")
	
	# Drop multiple items
	for i in range(2):  # Drop 2 items
		var item_to_drop = {}
		
		if randf() < 0.6:  # 60% bình máu
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = items_texture
			atlas_texture.region = Rect2(0, 0, 24, 24)
			
			item_to_drop = {
				"item_type": "Tiêu hao",
				"item_name": "Bình máu",
				"item_texture": atlas_texture,
				"item_effect": "heal",
				"quantity": 1
			}
		else:  # 40% than đá
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = items_texture
			atlas_texture.region = Rect2(24, 0, 24, 24)
			
			item_to_drop = {
				"item_type": "Vật liệu",
				"item_name": "Than đá",
				"item_texture": atlas_texture,
				"item_effect": "",
				"quantity": 2
			}
		
		# Drop với offset để không chồng lên nhau
		var drop_pos = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		Global.drop_item(item_to_drop, drop_pos, get_parent())

func _on_area_2d_body_entered(body: Node2D):
	"""Xử lý va chạm với player"""
	if body.name == "Player" and not is_dead:
		if body.has_method("take_damaged"):
			body.take_damaged(contact_damage)
			print("[Golem] Contact damage to player: ", contact_damage)
