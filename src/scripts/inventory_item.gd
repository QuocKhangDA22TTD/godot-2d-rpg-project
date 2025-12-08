@tool
extends Node2D

var player_in_range = false

@export var item_type: String
@export var item_name: String
@export var item_texture: Texture:
	set(value):
		item_texture = value
		if is_node_ready() and not Engine.is_editor_hint():
			icon_sprite.texture = value
@export var item_effect = ""
var scene_path: String = "res://scenes/entity/inventory_item.tscn"

@onready var icon_sprite = $Sprite2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		icon_sprite.texture = item_texture

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		icon_sprite.texture = item_texture
	
	if player_in_range and Input.is_action_just_pressed("pickup_item"):
		pickup_item()

func pickup_item():
	if Global.player == null:
		return
	
	# Kiểm tra xem item này có được yêu cầu bởi bất kỳ quest nào không
	if Global.player.is_item_needed(item_name):
		# Item này cần cho quest - không thêm vào inventory mà gọi check_quest_objectives
		Global.player.check_quest_objectives(item_name, "Collection")
		print("Item nhặt được cho quest: " + item_name)
		self.queue_free()
	else:
		# Item này không cần cho quest - thêm vào inventory
		var item = {
			"quantity": 1,
			"item_type": item_type,
			"item_name": item_name,
			"item_texture": item_texture,
			"item_effect": item_effect,
			"scene_path": scene_path,
		}
		Global.add_item(item)
		print("Item thêm vào inventory: " + item_name)
		self.queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		body.interact_ui.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		body.interact_ui.visible = false

func set_data_item(data):
	item_type = data["item_type"]
	item_name = data["item_name"]
	item_effect = data["item_effect"]
	item_texture = data["item_texture"]
