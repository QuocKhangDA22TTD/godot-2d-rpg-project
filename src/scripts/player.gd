extends CharacterBody2D

var speed = 60.0
var health = 3.0

var is_open_inventory = false

@onready var anima = $AnimatedSprite2D
@onready var colli = $CollisionShape2D
@onready var weapon = $Weapon
@onready var health_label = $PlayerStatusUI/Control/HeatlhLabel
@onready var anim_player = $AnimatedSprite2D/AnimationPlayer
@onready var inventory_ui = $InventoryUI
@onready var interact_ui = $InteracUI
#@onready var usage_panel_ui = $InventoryUI/UsagePanel

signal died

func _ready():
	var data = GameManager.load_game()
	
	if NavigationManager.on_trigger_player_spawn.connect(_on_spawn):
		pass
	else:
		load_position(data)
		
	Global.player = self
	anim_player.play("RESET")
	anima.play("idle")
	Global.facing = false
	health_label.text = "Máu: " + str(health)
	#Global.usage_panel_signal.connect(_on_usage_panel_signal)

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
	player_movement()
	player_animation()
	#show_info()
	move_and_slide()

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and !PauseMenu.visible:
		inventory_ui.visible = !inventory_ui.visible
		Global.inventory_updated.emit()
		#if !inventory_ui.visible:
			#usage_panel_ui.visible = false
		get_tree().paused = !get_tree().paused

func _on_usage_panel_signal():
	pass
	#usage_panel_ui.visible = !usage_panel_ui.visible

func apply_item_effect (item):
	match item["item_effect"]:
		"Hồi máu":
			if health < 10:
				health += 4
