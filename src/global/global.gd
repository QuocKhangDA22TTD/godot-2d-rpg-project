extends Node

var player = null
var facing = false
var inventory = []

@onready var inventory_slot_scene = preload("res://scenes/ui/inventory_slot.tscn")

signal inventory_updated
signal usage_panel_signal

func _ready():
	inventory.resize(24)

func add_item(item):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item_name"] == item["item_name"]:
			inventory[i]["quantity"] += item["quantity"]
			#inventory_updated.emit()
			print("add: ", inventory)
			return true
		elif inventory[i] == null:
			inventory[i] = item
			#inventory_updated.emit()
			print("add: ", inventory)
			return true
	return false

func remove_item(item_name):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item_name"] == item_name:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			print("remove: ", inventory)
			inventory_updated.emit()
			return true
	return false

func increase_item():
	pass

func adjust_drop_position(position):
	var radius = 8
	var nearby_items = get_tree().get_nodes_in_group("Items")
	for item in nearby_items:
		if item.global_position.distance_to(position) < radius:
			var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			position += random_offset
			break
	return position

func drop_item(item_data, drop_position):
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_data_item(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
