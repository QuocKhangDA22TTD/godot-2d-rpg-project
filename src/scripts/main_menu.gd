extends Control

@onready var option_ui = $OptionUI

func _ready():
	AudioManager.stop_music()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_start_game_pressed() -> void:
	# Chuyển đến loading screen để tiếp tục game
	var game_data = GameManager.load_game()
	var target_scene = game_data["scene"]
	_go_to_loading_screen(target_scene, false)

func _on_new_game_pressed() -> void:
	# Xóa toàn bộ dữ liệu game cũ
	GameManager.reset_all_game_data()
	
	# Chuyển đến loading screen để bắt đầu game mới
	var default_scene = "res://scenes/map/main_map.tscn"
	_go_to_loading_screen(default_scene, true)

func _go_to_loading_screen(target_scene: String, is_new_game: bool):
	"""Chuyển đến loading screen với thông tin đích"""
	# Dừng nhạc menu khi rời khỏi main menu
	AudioManager.stop_music()
	
	# Lưu thông tin vào Global để loading screen có thể truy cập
	Global.loading_target_scene = target_scene
	Global.loading_is_new_game = is_new_game
	
	var loading_scene = load("res://scenes/ui/loading_screen.tscn")
	get_tree().paused = false
	get_tree().change_scene_to_packed(loading_scene)

func _on_option_pressed() -> void:
	"""Hiển thị/ẩn option UI"""
	option_ui.visible = !option_ui.visible

func _input(event):
	"""Xử lý input để đóng option UI bằng ESC"""
	if event.is_action_pressed("ui_cancel") and option_ui.visible:
		option_ui.visible = false
