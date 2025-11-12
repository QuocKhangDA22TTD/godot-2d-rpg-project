extends Control

@onready var icon = $TextureRect/ItemIcon
@onready var item_quantity = $TextureRect/ItemQuantity
@onready var details_panel = $DetailsPanel
@onready var item_name = $DetailsPanel/ItemName
@onready var item_type = $DetailsPanel/ItemType
@onready var item_effect = $DetailsPanel/ItemEffect
@onready var usage_panel = $UsagePanel
@onready var use_button = $UsagePanel/TextureRect/VBoxContainer/UseButton

var item = null

func _on_item_button_pressed() -> void:
	if item != null:
		usage_panel.visible = !usage_panel.visible
		#Global.usage_panel_signal.emit()
		if usage_panel.visible:
			details_panel.visible = false
		else:
			details_panel.visible = true

func _on_item_button_mouse_entered() -> void:
	if item != null:
		if usage_panel.visible:
			usage_panel.visible = true
			details_panel.visible = false
		elif !usage_panel.visible:
			usage_panel.visible = false
			details_panel.visible = true

func _on_item_button_mouse_exited() -> void:
	details_panel.visible = false
	usage_panel.visible = false

func set_empty():
	icon.texture = null
	item_quantity.text = ""

func set_item(new_item):
	item = new_item
	icon.texture = new_item["item_texture"]
	item_quantity.text = str(new_item["quantity"])
	item_name.text = "Tên: " + str(new_item["item_name"])
	item_type.text = "Loại: " + str(new_item["item_type"])
	if new_item["item_effect"] != "":
		item_effect.text = "Hiệu ứng: " + str(new_item["item_effect"])
	else:
		use_button.visible = false
		item_effect.text = "Hiệu ứng: Không có hiệu ứng"

func _on_drop_button_pressed() -> void:
	if item != null:
		var drop_position = Global.player.global_position
		Global.drop_item(item, drop_position)
		Global.remove_item(item["item_name"])
	usage_panel.visible = false

func _on_texture_rect_mouse_entered() -> void:
	usage_panel.visible = true

func _on_texture_rect_mouse_exited() -> void:
	usage_panel.visible = false

func _on_use_button_pressed() -> void:
	if item != null and item["item_effect"] != "" and Global.player != null:
		Global.player.apply_item_effect(item)
		Global.remove_item(item["item_name"])
		Global.player.change_health_label()
	usage_panel.visible = false

func _on_visibility_changed() -> void:
	if !visible:
		details_panel.visible = false
		usage_panel.visible = false
