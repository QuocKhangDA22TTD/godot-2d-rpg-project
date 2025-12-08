extends Resource

class_name Quest

@export var quest_id: String
@export var quest_name: String
@export var quest_description: String
@export var state: String = "not_started"
@export var unlock_id: String
@export var objectives: Array[Objectives] = []
@export var rewards: Array[Rewards] = []

@export var is_repeatable: bool = false

func is_completed() -> bool:
	for objective in objectives:
		print("[DEBUG Quest.gd] is_completed() check - objective.id=", objective.id, ", is_completed=", objective.is_completed)
		if not objective.is_completed:
			return false
	print("[DEBUG Quest.gd] Quest ", quest_id, " is_completed() trả về TRUE")
	return true

func complete_objective(objective_id: String, quantity: int = 1):
	for objective in objectives:
		if objective.id == objective_id:
			if objective.target_type == "Collection":
				objective.collected_quantity += quantity
				if objective.collected_quantity >= objective.required_quantity:
					objective.is_completed = true
					print("[DEBUG Quest.gd] Objective hoàn thành: ", objective.id, ", collected=", objective.collected_quantity, ", required=", objective.required_quantity, ", is_completed=", objective.is_completed)
			elif objective.target_type == "talk_to":
				objective.is_completed = true
				print("[DEBUG Quest.gd] Talk_to objective hoàn thành: ", objective.id)
			break

func reset_quest():
	state = "not_started"
	for objective in objectives:
		objective.is_completed = false
		objective.collected_quantity = 0
