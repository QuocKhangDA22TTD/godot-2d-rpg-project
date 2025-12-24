extends Control

@onready var panel = $CanvasLayer
@onready var dialog_speaker = $CanvasLayer/TextureRect/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/TextureRect/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/TextureRect/Panel/DialogBox/DialogOptions
@onready var close_button = $CanvasLayer/TextureRect/Panel/CloseButton

func _ready() -> void:
	hide_dialog()

func show_dialog(speaker, text, options):
	print("[DialogUI] Showing dialog for speaker: ", speaker)
	print("[DialogUI] CanvasLayer visible before: ", panel.visible)
	print("[DialogUI] CanvasLayer layer: ", panel.layer)
	
	close_button.visible = true
	if GameManager.state == GameManager.GameState.CUTSCENE:
		close_button.visible = false
	
	# Đảm bảo CanvasLayer có layer thích hợp
	panel.layer = 10  # Đặt layer cao hơn skip UI (layer 50) nhưng thấp hơn các UI khác
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
	
	print("[DialogUI] Dialog shown - CanvasLayer visible: ", panel.visible, ", layer: ", panel.layer)

func _on_option_selected(option):
	get_parent().handle_dialog_choice(option)

func hide_dialog():
	print("[DialogUI] Hiding dialog - CanvasLayer visible before: ", panel.visible)
	panel.visible = false
	if Global.player != null:
		Global.player.can_move = true
		print("[DialogUI] Player can_move restored: ", Global.player.can_move)
	print("[DialogUI] Dialog hidden - CanvasLayer visible: ", panel.visible)

func _on_close_button_pressed() -> void:
	hide_dialog()
