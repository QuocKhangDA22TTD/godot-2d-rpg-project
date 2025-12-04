extends CharacterBody2D

var current_state = "start"
var current_branch_index = 0

@onready var dialog_manager = $DialogManager

@export var npc_id: String
@export var npc_name: String
@export var dialog_resource: Dialog

@export var quests: Array[Quest] = []
var quest_manager = null

func _ready() -> void:
	dialog_resource.load_from_json("res://resources/dialog/dialog_data.json")
	dialog_manager.npc = self
	
	await get_tree().create_timer(0.05).timeout
	quest_manager = Global.player.quest_manager

func start_dialog():
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	if npc_dialog.is_empty():
		return
	dialog_manager.show_dialog(self)

func get_current_dialog():
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	if current_branch_index < npc_dialog.size():
		for dialog in npc_dialog[current_branch_index]["dialogs"]:
			#print(dialog)
			#print(dialog["state"])
			#print(current_state)
			if dialog["state"] == current_state:
				return dialog
	#print(current_state)
	return null

func set_dialog_tree(branch_index):
	current_branch_index = branch_index
	current_state = "start"

func set_dialog_state(state):
	current_state = state

func offer_quest(quest_id: String):
	for quest in quests:
		if quest.quest_id == quest_id and quest.state == "not_started":
			quest.state = "in_progress"
			quest_manager.add_quest(quest)
			return
	print("Không tìm thấy nhiệm vụ hoặc nhiệm vụ đã được bắt đầu trước đó")

func get_quest_dialog() -> Dictionary:
	var active_quests = quest_manager.get_active_quests()
	
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.target_id == npc_id and objective.target_type == "talk_to" and not objective.is_completed:
				print("xin chao")
				print(current_state)
				if current_state == "start":
					return {"text": objective.objective_dialog, "options": {"Rời đi": "exit"}}
	return {"text": "", "options": {}}
