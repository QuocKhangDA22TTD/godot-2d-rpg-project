@tool
extends Node2D

var player_in_range = false

@export var item_type: String
@export var item_name: String
@export var item_texture: Texture
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
	var item = {
		"quantity": 1,
		"item_type": item_type,
		"item_name": item_name,
		"item_texture": item_texture,
		"item_effect": item_effect,
		"scene_path": scene_path,
	}
	if Global.player != null:
		Global.add_item(item)
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
