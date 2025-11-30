extends Control

var selected_quest: Quest = null
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

func show_hide_log():
	panel.visible = !panel.visible
	update_quest_list()
	if selected_quest:
		_on_quest_selected(selected_quest)

func update_quest_list():
	for child in quest_list.get_children():
		quest_list.remove_child(child)
	
	var active_quests = get_parent().get_active_quests()
	if active_quests.size() == 0:
		clear_quest_details()
		# Global.player.selected_quest = null
		# Global.player.update_quest_tracker(null)
	else:
		for quest in active_quests:
			var button = Button.new()
			button.add_theme_font_size_override("font_size", 20)
			button.text = quest.quest_name
			button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list.add_child(button)

func _on_quest_selected(quest: Quest):
	selected_quest = quest
	
	quest_title.text = quest.quest_name
	quest_description = quest.quest_description
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
	
	for objective in quest.objectives:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 20)
		
		if objective.target_type == "collection":
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
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
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_font_color_override("font_color", Color(0, 0.84, 0))
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
	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		update_quest_list()

func _on_objectives_updated(quest_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		_on_quest_selected(selected_quest)
	else:
		clear_quest_details()
