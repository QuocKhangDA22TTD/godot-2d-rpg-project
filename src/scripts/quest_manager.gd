extends Node2D

@onready var quest_ui = $QuestUI

signal quest_updated(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String)
signal quest_list_upadated()

var quests = {}
var npc = null

func _ready():
	# Load quest đã lưu khi quest_manager khởi động
	load_saved_quests()

func add_quest(quest: Quest):
	print("[QuestManager] Adding quest: ", quest.quest_name, " (", quest.quest_id, ") with state: ", quest.state)
	quests[quest.quest_id] = quest
	quest_updated.emit(quest.quest_id)
	save_quests()  # Tự động lưu khi thêm quest
	print("[QuestManager] Quest added successfully. Total quests: ", quests.size())

func remove_quest(quest_id: String):
	quests.erase(quest_id)
	quest_list_upadated.emit()
	save_quests()  # Tự động lưu khi xóa quest

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id, null)

func update_quest(quest_id: String, state: String):
	var quest = get_quest(quest_id)
	
	if quest:
		quest.state = state
		quest_updated.emit(quest_id)
		if state == "completed":
			if quest.is_repeatable:
				# Nếu quest có thể lặp lại - giữ nguyên state "completed" để NPC có thể reset khi cần
				print("[QuestManager] Quest ", quest_id, " completed and is repeatable")
				save_quests()
			else:
				# Nếu không lặp lại - xóa quest
				remove_quest(quest_id)
		else:
			save_quests()  # Tự động lưu khi cập nhật trạng thái

func get_active_quests() -> Array:
	var active_quests = []
	
	print("[QuestManager] Getting active quests. Total quests: ", quests.size())
	for quest in quests.values():
		print("[QuestManager] Quest: ", quest.quest_name, " - State: ", quest.state)
		if quest.state == "in_progress":
			active_quests.append(quest)
	
	print("[QuestManager] Found ", active_quests.size(), " active quests")
	return active_quests

func complete_objective(quest_id: String, objective_id: String):
	var quest = get_quest(quest_id)
	
	if quest:
		quest.complete_objective(objective_id)
		objective_updated.emit(quest_id, objective_id)
		save_quests()  # Tự động lưu khi hoàn thành objective

func show_hide_log():
	quest_ui.show_hide_log()

func save_quests():
	"""Gọi GameManager để lưu quest"""
	if GameManager:
		GameManager.save_quests(quests)

func load_saved_quests():
	"""Load quest từ file lưu"""
	if not GameManager:
		print("GameManager không tồn tại")
		return
	
	var quest_data = GameManager.load_quests()
	
	if quest_data.is_empty():
		print("Không có quest đã lưu")
		return
	
	# Khôi phục quest từ dữ liệu đã lưu
	for quest_id in quest_data:
		var data = quest_data[quest_id]
		
		# Tạo quest instance
		var quest = Quest.new()
		quest.quest_id = data.get("quest_id", "")
		quest.quest_name = data.get("quest_name", "")
		quest.quest_description = data.get("quest_description", "")
		quest.state = data.get("state", "not_started")
		quest.unlock_id = data.get("unlock_id", "")
		quest.is_repeatable = data.get("is_repeatable", false)
		
		# Khôi phục objectives
		if data.has("objectives"):
			for obj_data in data["objectives"]:
				var objective = Objectives.new()
				objective.id = obj_data.get("id", "")
				objective.description = obj_data.get("description", "")
				objective.target_type = obj_data.get("target_type", "")
				objective.target_id = obj_data.get("target_id", "")
				objective.objective_dialog = obj_data.get("objective_dialog", "")
				objective.required_quantity = obj_data.get("required_quantity", 0)
				objective.collected_quantity = obj_data.get("collected_quantity", 0)
				objective.is_completed = obj_data.get("is_completed", false)
				
				quest.objectives.append(objective)
		
		# Khôi phục rewards
		if data.has("rewards"):
			for reward_data in data["rewards"]:
				var reward = Rewards.new()
				reward.reward_type = reward_data.get("reward_type", "")
				reward.reward_amount = reward_data.get("reward_amount", 0)
				quest.rewards.append(reward)
		
		# Thêm quest vào quests dict (không gọi add_quest để tránh save lại)
		quests[quest_id] = quest
		print("Khôi phục quest: ", quest_id)
	
	# Emit signal để cập nhật UI
	quest_list_upadated.emit()
	print("Đã load ", quests.size(), " quest từ file lưu")
	
	# Cập nhật UI cho từng quest được load
	for quest_id in quests:
		quest_updated.emit(quest_id)
