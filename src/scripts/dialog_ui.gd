extends Control

@onready var panel = $CanvasLayer
@onready var dialog_speaker = $CanvasLayer/TextureRect/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/TextureRect/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/TextureRect/Panel/DialogBox/DialogOptions
@onready var close_button = $CanvasLayer/TextureRect/Panel/CloseButton

func _ready() -> void:
	hide_dialog()

func show_dialog(speaker, text, options):
	close_button.visible = true
	if GameManager.state == GameManager.GameState.CUTSCENE:
		close_button.visible = false
	
	panel.visible = true
	
	dialog_speaker.text = speaker
	dialog_text.text = text
	
	for dialog in dialog_options.get_children():
		dialog_options.remove_child(dialog)
	
	for option in options.keys():
		var button = Button.new()
		button.text = option
		button.add_theme_font_size_override("font_size", 4)
		#button.autowrap_mode = true
		button.pressed.connect(_on_option_selected.bind(option))
		dialog_options.add_child(button)

func _on_option_selected(option):
	get_parent().handle_dialog_choice(option)

func hide_dialog():
	panel.visible = false
	if Global.player != null:
		Global.player.can_move = true

func _on_close_button_pressed() -> void:
	hide_dialog()
