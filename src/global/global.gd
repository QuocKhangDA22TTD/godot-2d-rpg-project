extends Node

var player = null
var inventory = []

# Loading screen variables
var loading_target_scene: String = ""
var loading_is_new_game: bool = false
var loading_from_pause: bool = false

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
			#print("add: ", inventory)
			GameManager.save_inventory(inventory)  # Lưu inventory sau khi thêm item
			return true
		elif inventory[i] == null:
			inventory[i] = item
			#inventory_updated.emit()
			#print("add: ", inventory)
			GameManager.save_inventory(inventory)  # Lưu inventory sau khi thêm item
			return true
	return false

func remove_item(item_name):
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["item_name"] == item_name:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			#print("remove: ", inventory)
			inventory_updated.emit()
			GameManager.save_inventory(inventory)  # Lưu inventory sau khi xóa item
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

func drop_item(item: Dictionary, drop_position: Vector2, parent_node: Node = null):
	"""Drop item at a specific position in the world"""
	# Adjust drop position nếu có item khác ở gần
	var adjusted_pos = adjust_drop_position(drop_position)
	
	# Tạo instance của inventory_item scene
	var item_instance = preload("res://scenes/entity/inventory_item.tscn").instantiate()
	
	# Set dữ liệu của item
	item_instance.item_type = item["item_type"]
	item_instance.item_name = item["item_name"]
	item_instance.item_texture = item["item_texture"]
	item_instance.item_effect = item["item_effect"]
	
	# Set vị trí drop
	item_instance.global_position = adjusted_pos
	
	# Thêm vào đúng parent (map hoặc scene hiện tại)
	if parent_node:
		parent_node.add_child(item_instance)
	else:
		get_tree().current_scene.add_child(item_instance)
	
	item_instance.add_to_group("Items")
	print("[Global] Item dropped: ", item["item_name"], " at ", adjusted_pos)
