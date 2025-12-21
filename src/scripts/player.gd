extends CharacterBody2D

var speed = 60.0
var health = 30.0
var max_health = 5.0

#var is_open_inventory = false # Để đây một thời gian xem có chuyện gì xảy ra không, nếu không có thì bỏ dòng này
var can_move = true
var coin_amount = 0
var is_attacking = false
var facing_direction = Vector2.RIGHT  # Hướng mặt của player

# Footstep sound variables
var last_footstep_frame = -1
var footstep_frames = [1, 3]  # Frames khi phát âm thanh bước chân

@onready var anima = $AnimatedSprite2D
@onready var colli = $CollisionShape2D
@onready var weapon = $Weapon
@onready var health_label = $HUD/HeatlhLabel
@onready var anim_player = $AnimatedSprite2D/AnimationPlayer
@onready var inventory_ui = $InventoryUI
@onready var interact_ui = $InteracUI
@onready var ray_cast_2d = $RayCast2D
@onready var quest_manager = $QuestManager
@onready var coin_amount_label = $HUD/CoinAmount
@onready var weapon_pivot = $WeaponPivot
@onready var weapon_handler = $WeaponHandler
@onready var weapon_sprite = $WeaponPivot/WeaponSprite
@onready var weapon_anim = $WeaponPivot/AnimationPlayer

signal died

func _ready():
	var data = GameManager.load_game()
	
	if NavigationManager.on_trigger_player_spawn.connect(_on_spawn):
		pass
	else:
		load_position(data)
		# Load coins nếu có
		if typeof(data) == TYPE_DICTIONARY and data.has("coins"):
			coin_amount = int(data.get("coins", 0))
		# Load health nếu có
		if typeof(data) == TYPE_DICTIONARY and data.has("health"):
			health = float(data.get("health", max_health))
			max_health = float(data.get("max_health", 5.0))
		
	Global.player = GameManager.player
	#Global.player.health = data["health"]
	anim_player.play("RESET")
	anima.play("idle")
	health_label.text = "Máu: " + str(health)
	
	# Load inventory từ file
	var loaded_inventory = GameManager.load_inventory()
	if loaded_inventory.size() > 0:
		Global.inventory = loaded_inventory
		print("Đã tải inventory từ file: ", loaded_inventory.size(), " slots")
	
	update_coins()
	
	# Kết nối signal để theo dõi frame animation
	anima.frame_changed.connect(_on_animation_frame_changed)

func _physics_process(delta: float) -> void:
	if GameManager.game_over:
		anima.stop()
		if get_tree().current_scene.name != "MainMap":
			# Reset health về max khi chuyển scene sau khi chết
			health = max_health
			change_health_label()
			GameManager.save_player_positon()  # Lưu health reset
			await NavigationManager.go_to_level("main_map", "Village")
			GameManager.game_over = false
		return
	if get_tree().paused:
		anima.pause()
		return
	if can_move and GameManager.state == 0:
		player_movement()
		player_animation()
		move_and_slide()
		_handle_attack()
		
		if velocity != Vector2.ZERO:
			ray_cast_2d.target_position = velocity.normalized() * 15

func player_movement():
	var hor = Input.get_action_strength("right") - Input.get_action_strength("left")
	var ver = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	var dir = Vector2(hor, ver)
	
	velocity = dir * speed

func player_animation():
	# Chỉ cập nhật hướng khi không đang tấn công
	if not is_attacking:
		if velocity.x < 0:
			anima.flip_h = true
			facing_direction = Vector2.LEFT
		elif velocity.x > 0:
			anima.flip_h = false
			facing_direction = Vector2.RIGHT
	
	# Animation đơn giản
	if velocity != Vector2.ZERO:
		anima.play("run")
	else:
		anima.play("idle")
		_reset_footstep_tracking()

func load_position(data: Dictionary):
	global_position.x = data["x"]
	global_position.y = data["y"]

func change_health_label():
	health_label.text = "Máu: " + str(health)

func _on_spawn(position: Vector2):
	global_position = position

func take_damaged(amount):
	if health <= 0:
		return
	
	if anim_player.current_animation == "hit":
		return
	
	health -= amount
	anim_player.play("hit")
	AudioManager.play_sfx("player_damaged")
	change_health_label()
	
	if health <= 0:
		emit_signal("died")

func apply_item_effect (item):
	match item["item_effect"]:
		"heal":  # Khớp với giá trị trong coal_monster.gd
			health += 3
			health = clamp(health, 0, max_health)
			change_health_label()  # Cập nhật label ngay lập tức
	# Lưu inventory sau khi thay đổi
	GameManager.save_inventory(Global.inventory)
	GameManager.save_player_positon()  # Lưu health mới

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and !PauseMenu.visible:
		inventory_ui.visible = !inventory_ui.visible
		Global.inventory_updated.emit()
		get_tree().paused = !get_tree().paused
		
	if can_move:
		if event.is_action_pressed("talk"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("NPC"):
					can_move = false
					target.start_dialog()
					check_quest_objectives(target.npc_id, "talk_to")
				elif target.is_in_group("Items"):
					# Gọi pickup_item từ inventory_item.gd để xử lý
					target.get_parent().pickup_item()
	
	if event.is_action_pressed("quest"):
		quest_manager.show_hide_log()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Lưu trạng thái trước khi thoát game
		GameManager.save_player_positon()
		GameManager.save_inventory(Global.inventory)
		quest_manager.save_quests()
		print("Đã lưu tất cả dữ liệu trước khi thoát game")
		get_tree().quit()

func is_item_needed(item_name: String) -> bool:
	var quests = quest_manager.get_active_quests()
	
	for quest in quests:
		for objective in quest.objectives: 
			if objective.target_id == item_name and objective.target_type == "Collection" and not objective.is_completed:
				return true
	return false

func check_quest_objectives(target_id: String, target_type: String, quantity: int = 1):
	print("[DEBUG] check_quest_objectives được gọi với target_id=", target_id, ", target_type=", target_type, ", quantity=", quantity)
	
	var quests = quest_manager.get_active_quests()
	print("[DEBUG] Số quest đang hoạt động: ", quests.size())
	
	if quests.is_empty():
		print("Không có quest nào đang hoạt động")
		return

	for quest in quests:
		print("[DEBUG] Kiểm tra quest: ", quest.quest_name, " (", quest.quest_id, ")")
		var objective_updated = false
		
		for objective in quest.objectives:
			print("[DEBUG] Objective: id=", objective.id, ", target_id=", objective.target_id, ", target_type=", objective.target_type, ", is_completed=", objective.is_completed)
			
			if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
				print("Cập nhật mục tiêu - Quest: " + quest.quest_name + ", Target: " + target_id + ", Quantity trước: " + str(objective.collected_quantity))
				quest.complete_objective(objective.id, quantity)
				print("Quantity sau: " + str(objective.collected_quantity) + "/" + str(objective.required_quantity))
				objective_updated = true
				# Emit signal via quest_manager and save progress so UI and file reflect update
				if quest_manager:
					quest_manager.objective_updated.emit(quest.quest_id, objective.id)
					quest_manager.save_quests()
				break

		if objective_updated and quest.is_completed():
			print("Quest hoàn thành: " + quest.quest_name)
			handle_quest_completion(quest)

func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "coins":
			print("[DEBUG] Trước khi cộng thưởng: coin_amount=", coin_amount, ", reward=", reward.reward_amount)
			coin_amount += reward.reward_amount
			update_coins()
			print("[DEBUG] Sau khi cộng thưởng: coin_amount=", coin_amount)
	# Lưu tiền ngay lập tức trước khi cập nhật trạng thái quest
	var saved_before = GameManager.save_player_positon()
	print("[DEBUG] save_player_positon() trước update_quest trả về:", saved_before)
	# Cập nhật trạng thái quest (có thể xóa hoặc reset tùy is_repeatable)
	quest_manager.update_quest(quest.quest_id, "completed")
	# Lưu lại player ngay sau khi cập nhật quest để chắc chắn
	var saved_after = GameManager.save_player_positon()
	print("[DEBUG] save_player_positon() sau update_quest trả về:", saved_after)

func update_coins():
	coin_amount_label.text = str(coin_amount)

func _on_animation_frame_changed():
	"""Xử lý khi frame animation thay đổi - phát âm thanh bước chân"""
	# Chỉ phát âm thanh khi đang chạy animation "run" và thực sự đang di chuyển
	if anima.animation != "run" or velocity == Vector2.ZERO:
		return
	
	if not can_move:
		anima.play("idle")
		_reset_footstep_tracking()
	
	var current_frame = anima.frame
	
	# Kiểm tra xem có phải frame cần phát âm thanh không (frame 0 và 2)
	if current_frame in footstep_frames:
		# Tránh phát âm thanh trùng lặp cho cùng một frame
		if current_frame != last_footstep_frame:
			_play_footstep_sound()
			last_footstep_frame = current_frame
			print("[Player] Footstep sound played at frame: ", current_frame)

func _play_footstep_sound():
	"""Phát âm thanh bước chân trên đất"""
	AudioManager.play_sfx("dirt_footstep")

func _reset_footstep_tracking():
	"""Reset tracking footstep khi thay đổi animation"""
	last_footstep_frame = -1

func _handle_attack():
	if Input.is_action_just_pressed("attack"):
		weapon_handler.attack(self, facing_direction)

func move_to(target: Vector2) -> void:
	while global_position.distance_to(target) > 2:
		velocity = (target - global_position).normalized() * speed
		move_and_slide()
		await get_tree().physics_frame
		
	velocity = Vector2.ZERO
