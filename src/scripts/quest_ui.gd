extends Control

var quest_manager: Node = null

@onready var panel = $CanvasLayer/Panel
@onready var quest_list = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title = $CanvasLayer/Panel/Contents/Details/QuestDetail/QuestTitle
@onready var quest_description = $CanvasLayer/Panel/Contents/Details/QuestDetail/QuestDescription
@onready var quest_objectives = $CanvasLayer/Panel/Contents/Details/QuestDetail/QuestObjectives
@onready var quest_rewards = $CanvasLayer/Panel/Contents/Details/QuestDetail/QuestRewards

func _ready() -> void:
	panel.visible = false
	clear_quest_details()
	
	quest_manager = get_parent()
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objectives_updated)
	quest_manager.quest_list_upadated.connect(_on_quest_list_updated)

func show_hide_log():
	panel.visible = !panel.visible
	update_quest_list()

func update_quest_list():
	for child in quest_list.get_children():
		quest_list.remove_child(child)
	
	var active_quests = get_parent().get_active_quests()
	if active_quests.size() == 0:
		clear_quest_details()
		# Global.player.update_quest_tracker(null)
	else:
		for quest in active_quests:
			var button = Button.new()
			button.add_theme_font_size_override("font_size", 20)
			button.text = quest.quest_name
			button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list.add_child(button)

		# Auto-select first active quest so UI shows progress immediately
		if active_quests.size() > 0:
			_on_quest_selected(active_quests[0])

func _on_quest_selected(quest: Quest):
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
	
	for objective in quest.objectives:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 8)
		
		if objective.target_type == "Collection":
			label.text = objective.description + " (" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else:
			label.text = objective.description
		
		if objective.is_completed:
			label.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			label.add_theme_color_override("font_color", Color(1, 0, 0))
		
		quest_objectives.add_child(label)
	
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
	
	for reward in quest.rewards:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0, 0.84, 0))
		label.text = "Phần thưởng: " + reward.reward_type.capitalize() + ": " + str(reward.reward_amount)
		quest_rewards.add_child(label) 

func clear_quest_details():
	quest_title.text = ""
	quest_description.text = ""
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
	
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)

func _on_quest_updated(quest_id: String):
	update_quest_list()

func _on_objectives_updated(quest_id: String):
	update_quest_list()

func _on_quest_list_updated():
	"""Cập nhật khi danh sách quest thay đổi (như khi load từ file)"""
	update_quest_list()
