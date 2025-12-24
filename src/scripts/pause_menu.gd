extends CanvasLayer

@onready var option_ui = $OptionUI

func _input(event: InputEvent):
	# Chặn pause menu khi đang trong cutscene
	if GameManager.state == GameManager.GameState.CUTSCENE:
		return
	
	await get_tree().create_timer(0.05).timeout
	if get_tree().current_scene.name != "MainMenu":
		if event.is_action_pressed("esc"):
			# Nếu option UI đang mở, đóng nó trước
			if option_ui.visible:
				option_ui.visible = false
				return
			
			# Nếu inventory đang mở, đóng inventory
			if Global.player.inventory_ui.visible:
				Global.player.inventory_ui.visible = false
				get_tree().paused = !get_tree().paused
				return
			
			# Nếu không có gì mở, toggle pause menu
			self.visible = !self.visible
			get_tree().paused = !get_tree().paused

func _on_resume_pressed() -> void:
	self.visible = !self.visible
	get_tree().paused = !get_tree().paused

func _on_option_pressed() -> void:
	"""Hiển thị/ẩn option UI"""
	option_ui.visible = !option_ui.visible

func _on_save_and_quit_pressed() -> void:
	"""Lưu game và thoát về menu"""
	self.visible = false
	option_ui.visible = false
	get_tree().paused = false
	AudioManager.stop_music()
	
	# Lưu game trước khi thoát
	GameManager.save_player_positon()
	GameManager.save_inventory(Global.inventory)
	if Global.player and Global.player.quest_manager:
		Global.player.quest_manager.save_quests()
	
	# Chuyển đến loading screen để quay về main menu
	_go_to_loading_screen("res://scenes/ui/main_menu.tscn", false)

func _on_quit_pressed() -> void:
	"""Thoát về menu không lưu"""
	self.visible = false
	option_ui.visible = false
	get_tree().paused = false
	AudioManager.stop_music()
	
	# Không lưu game, chỉ quay về menu
	_go_to_loading_screen("res://scenes/ui/main_menu.tscn", false)

func _go_to_loading_screen(target_scene: String, is_new_game: bool):
	"""Chuyển đến loading screen với thông tin đích"""
	# Lưu thông tin vào Global để loading screen có thể truy cập
	Global.loading_target_scene = target_scene
	Global.loading_is_new_game = is_new_game
	Global.loading_from_pause = true  # Đánh dấu đang load từ pause menu
	
	var loading_scene = load("res://scenes/ui/loading_screen.tscn")
	get_tree().change_scene_to_packed(loading_scene)
