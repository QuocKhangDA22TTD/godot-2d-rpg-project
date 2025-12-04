extends CharacterBody2D

var speed = 60.0
var health = 5.0
var max_health = 5.0

#var is_open_inventory = false # Để đây một thời gian xem có chuyện gì xảy ra không, nếu không có thì bỏ dòng này
var can_move = true
var selected_quest: Quest = null
var coin_amount = 0

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

signal died

func _ready():
	var data = GameManager.load_game()
	
	if NavigationManager.on_trigger_player_spawn.connect(_on_spawn):
		pass
	else:
		load_position(data)
		
	Global.player = GameManager.player
	#Global.player.health = data["health"]
	anim_player.play("RESET")
	anima.play("idle")
	Global.facing = false
	health_label.text = "Máu: " + str(health)
	
	update_coins()

func _physics_process(delta: float) -> void:
	if GameManager.game_over:
		anima.stop()
		if get_tree().current_scene.name != "MainMap":
			await NavigationManager.go_to_level("main_map", "Village")
			GameManager.game_over = false
		return
	if get_tree().paused:
		anima.pause()
		return
	if can_move:
		player_movement()
		player_animation()
		move_and_slide()
		
		if velocity != Vector2.ZERO:
			ray_cast_2d.target_position = velocity.normalized() * 15

func player_movement():
	var hor = Input.get_action_strength("right") - Input.get_action_strength("left")
	var ver = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	var dir = Vector2(hor, ver)
	
	velocity = dir * speed

func player_animation():	
	if velocity != Vector2.ZERO and Global.facing == false:
		if velocity.x < 0:
			anima.flip_h = true
		if velocity.x > 0:
			anima.flip_h = false
		anima.play("run")
	elif Global.facing == true:
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.x < global_position.x:
			anima.flip_h = true
			weapon.scale = Vector2(-1, 1)
		if mouse_pos.x > global_position.x:
			anima.flip_h = false
			weapon.scale = Vector2(1, 1)
		anima.play("run")
	else:
		anima.play("idle")

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
	change_health_label()
	
	if health <= 0:
		emit_signal("died")

func apply_item_effect (item):
	match item["item_effect"]:
		"Hồi máu":
			health += 3
			health = clamp(health, 0, max_health)

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
					if is_item_needed(target.get_parent().item_name):
						check_quest_objectives(target.get_parent().item_name, "Collection")
					else:
						print("item không cần thiết cho bất kìa mục tiêu nào")
	
	if event.is_action_pressed("quest"):
		quest_manager.show_hide_log()

func is_item_needed(item_name: String) -> bool:
	var quests = quest_manager.get_active_quests()
	
	for quest in quests:
		for objective in quest.objectives: 
			if objective.target_id == item_name and objective.target_type == "Collection" and not objective.is_completed:
				return true
	return false

func check_quest_objectives(target_id: String, target_type: String, quantity: int = 1):
	var quests = quest_manager.get_active_quests()
	if quests.is_empty():
		return

	for quest in quests:
		var objective_updated = false
		
		for objective in quest.objectives:
			if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
				print("hoàn thành mục tiêu của nhiệm vụ: " + quest.quest_name)
				quest.complete_objective(objective.id, quantity)
				objective_updated = true
				break

		if objective_updated and quest.is_completed():
			handle_quest_completion(quest)

func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "coins":
			coin_amount += reward.reward_amount
			update_coins()
	quest_manager.update_quest(quest.quest_id, "completed")

func update_coins():
	coin_amount_label.text = str(coin_amount)
