extends Node2D

var npc: Node = null

@onready var dialog_ui = $DialogUI

func show_dialog(npc, text = "", options = {}):
	if text != "":
		dialog_ui.show_dialog(npc.npc_name, text, options)
	else:
		var dialog = npc.get_current_dialog()
		if dialog == null:
			return
		dialog_ui.show_dialog(npc.npc_name, dialog["text"], dialog["options"])

func hide_dialog():
	dialog_ui.hide_dialog()

func handle_dialog_choice(option):
	var current_dialog = npc.get_current_dialog()
	if current_dialog == null:
		return
	
	var next_state = current_dialog["options"].get(option, "start")
	npc.set_dialog_state(next_state)
	
	if next_state == "end":
		if npc.current_branch_index < npc.dialog_resource.get_npc_dialog(npc.npc_id).size() - 1:
			npc.set_dialog_tree(npc.current_branch_index + 1)
		hide_dialog()
	elif next_state == "exit":
		npc.set_dialog_state("start")
		hide_dialog()
	elif next_state == "give_quest":
		pass
	else:
		show_dialog(npc)
