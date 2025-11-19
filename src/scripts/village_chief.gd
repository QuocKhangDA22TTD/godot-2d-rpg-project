extends CharacterBody2D

var current_state = "start"
var current_branch_index = 0

@onready var dialog_manager = $DialogManager

@export var npc_id: String
@export var npc_name: String
@export var dialog_resource: Dialog

func _ready() -> void:
	dialog_resource.load_from_json("res://resources/dialog/dialog_data.json")
	dialog_manager.npc = self

func start_dialog():
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	if npc_dialog.is_empty():
		return
	dialog_manager.show_dialog(self)

func get_current_dialog():
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	if current_branch_index < npc_dialog.size():
		for dialog in npc_dialog[current_branch_index]["dialogs"]:
			if dialog["state"] == current_state:
				return dialog
	return null

func set_dialog_tree(branch_index):
	current_branch_index = branch_index
	current_state = "state"

func set_dialog_state(state):
	current_state = state
