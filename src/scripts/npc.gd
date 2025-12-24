extends CharacterBody2D

var speed = 60.0

var current_state = "start"
var current_branch_index = 0  # Sẽ được set đúng trong _ready()

@onready var dialog_manager = $DialogManager

@export var npc_id: String
@export var npc_name: String
@export var dialog_resource: Dialog

@export var quests: Array[Quest] = []
var quest_manager = null

func _ready() -> void:
	dialog_resource.load_from_json("res://resources/dialog/dialog_data.json")
	dialog_manager.npc = self
	
	# Set branch index mặc định phù hợp cho từng NPC
	match npc_id:
		"trưởng làng":
			current_branch_index = 3  # Branch "npc_default"
		"hội trưởng":
			current_branch_index = 0  # Branch "nhận nhiệm vụ"
		"người bán hàng":
			current_branch_index = 0  # Branch "Chào Hỏi"
		"lính canh":
			current_branch_index = 0  # Branch "npc_default"
		_:
			current_branch_index = 0  # Default
	
	print("[NPC] ", npc_name, " (", npc_id, ") initialized with branch index: ", current_branch_index)
	
	await get_tree().create_timer(0.05).timeout
	quest_manager = Global.player.quest_manager

func start_dialog():
	print("[NPC] ", npc_name, " - Starting dialog...")
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	if npc_dialog.is_empty():
		print("[NPC] No dialog data found for npc_id: ", npc_id)
		return
	
	print("[NPC] Dialog data found, showing dialog...")
	dialog_manager.show_dialog(self)

func get_current_dialog():
	var npc_dialog = dialog_resource.get_npc_dialog(npc_id)
	print("[NPC] ", npc_name, " - Getting dialog for npc_id: ", npc_id)
	print("[NPC] Available branches: ", npc_dialog.size())
	print("[NPC] Current branch index: ", current_branch_index)
	print("[NPC] Current state: ", current_state)
	
	if current_branch_index < npc_dialog.size():
		var current_branch = npc_dialog[current_branch_index]
		print("[NPC] Current branch: ", current_branch["branch_id"])
		
		for dialog in current_branch["dialogs"]:
			if dialog["state"] == current_state:
				print("[NPC] Found matching dialog for state: ", current_state)
				return dialog
		
		print("[NPC] No dialog found for state: ", current_state)
	else:
		print("[NPC] Branch index ", current_branch_index, " out of range! Available branches: ", npc_dialog.size())
	
	return null

func set_dialog_tree(branch_index):
	current_branch_index = branch_index
	current_state = "start"

func set_dialog_state(state):
	current_state = state

func offer_quest(quest_id: String):
	print("[NPC] ", npc_name, " - Offering quest: ", quest_id)
	
	for quest in quests:
		if quest.quest_id != quest_id:
			continue

		print("[NPC] Found quest in NPC quests: ", quest.quest_name, ", state: ", quest.state, ", repeatable: ", quest.is_repeatable)

		# If quest already exists in quest_manager (e.g., loaded from save), reuse that instance
		var existing = null
		if quest_manager:
			existing = quest_manager.get_quest(quest.quest_id)

		if existing != null:
			print("[NPC] Found existing quest in quest_manager: ", existing.quest_name, ", state: ", existing.state)
			# existing is the authoritative instance (may contain saved progress)
			if existing.state == "not_started":
				existing.state = "in_progress"
				# ensure it's present (it already is), emit update and save
				quest_manager.quest_updated.emit(existing.quest_id)
				quest_manager.save_quests()
				print("Bạn đã nhận nhiệm vụ ", existing.quest_name)
				return
			elif existing.state == "completed" and quest.is_repeatable:
				print("[NPC] Resetting completed repeatable quest")
				existing.reset_quest()
				existing.state = "in_progress"
				quest_manager.quest_updated.emit(existing.quest_id)
				quest_manager.save_quests()
				print("Bạn đã nhận lại nhiệm vụ ", existing.quest_name)
				return
			elif existing.state == "in_progress":
				print("Nhiệm vụ đang được thực hiện")
				return
			else:
				print("Không thể nhận nhiệm vụ này - state: ", existing.state)
				return
		else:
			print("[NPC] No existing quest found, using NPC's local quest")
			# No existing saved instance — use NPC's local quest resource
			if quest.state == "not_started":
				quest.state = "in_progress"
				quest_manager.add_quest(quest)
				print("Bạn đã nhận nhiệm vụ ", quest.quest_name)
				return
			elif quest.state == "completed" and quest.is_repeatable:
				quest.reset_quest()
				quest.state = "in_progress"
				if quest_manager.get_quest(quest.quest_id) == null:
					quest_manager.add_quest(quest)
				print("Bạn đã nhận lại nhiệm vụ ", quest.quest_name)
				return
			else:
				print("Không thể nhận nhiệm vụ này")
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

func move_to(target: Vector2) -> void:
	while global_position.distance_to(target) > 2:
		velocity = (target - global_position).normalized() * speed
		move_and_slide()
		await get_tree().physics_frame
		
	velocity = Vector2.ZERO
