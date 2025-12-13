extends Control

var music_toggle: CheckButton
var close_button: Button

# Lưu trạng thái âm nhạc
var music_enabled: bool = true

func _ready():
	print("[OptionUI] _ready() được gọi")
	
	# Load trạng thái âm nhạc đã lưu
	load_audio_settings()
	print("[OptionUI] Trạng thái âm nhạc: ", music_enabled)
	
	# Lấy reference đến các node
	music_toggle = get_node("Panel/VBoxContainer/AudioSection/MusicToggle")
	close_button = get_node("Panel/VBoxContainer/CloseButton")
	
	# Kiểm tra xem các node có tồn tại không
	if music_toggle == null:
		print("Lỗi: Không tìm thấy MusicToggle node")
		return
	else:
		print("[OptionUI] Tìm thấy MusicToggle node")
	
	if close_button == null:
		print("Lỗi: Không tìm thấy CloseButton node")
		return
	else:
		print("[OptionUI] Tìm thấy CloseButton node")
	
	# Cập nhật UI theo trạng thái hiện tại
	music_toggle.button_pressed = music_enabled
	print("[OptionUI] Đã set button_pressed = ", music_enabled)
	
	# Kết nối signal
	music_toggle.toggled.connect(_on_music_toggle_toggled)
	close_button.pressed.connect(_on_close_button_pressed)
	print("[OptionUI] Đã kết nối signals")
	
	# Áp dụng trạng thái âm nhạc hiện tại
	_apply_music_setting()

func _on_music_toggle_toggled(pressed: bool):
	"""Xử lý khi người dùng bật/tắt âm nhạc"""
	print("[OptionUI] Toggle được nhấn: ", pressed)
	music_enabled = pressed
	_apply_music_setting()
	save_audio_settings()
	print("[OptionUI] Đã cập nhật trạng thái âm nhạc: ", music_enabled)

func _apply_music_setting():
	"""Áp dụng cài đặt âm nhạc"""
	print("[OptionUI] Áp dụng cài đặt âm nhạc: ", music_enabled)
	if music_enabled:
		# Bật âm nhạc - phát nhạc phù hợp với scene hiện tại
		print("[OptionUI] Bật âm nhạc")
		_play_appropriate_music()
	else:
		# Tắt âm nhạc
		print("[OptionUI] Tắt âm nhạc")
		AudioManager.stop_music()

func _play_appropriate_music():
	"""Phát nhạc phù hợp với scene hiện tại"""
	var current_scene = get_tree().current_scene
	
	print("[OptionUI] Scene hiện tại: ", current_scene.name)
	
	if current_scene.name == "MainMenu":
		AudioManager.play_music("menu")
	elif current_scene.name == "MainMap" or current_scene.has_method("_on_level_spawn"):
		# MainMap hoặc các scene game khác
		AudioManager.play_music("village_1")
	else:
		# Fallback cho các scene khác
		print("[OptionUI] Scene không xác định, không phát nhạc")
	# Có thể thêm các scene khác ở đây

func save_audio_settings():
	"""Lưu cài đặt âm thanh vào file"""
	var settings = {
		"music_enabled": music_enabled
	}
	
	var file = FileAccess.open("user://audio_settings.save", FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(settings)
		file.store_string(json_data)
		file.close()
		print("Đã lưu cài đặt âm thanh")

func load_audio_settings():
	"""Tải cài đặt âm thanh từ file"""
	var settings_path = "user://audio_settings.save"
	
	if not FileAccess.file_exists(settings_path):
		# Nếu chưa có file, sử dụng cài đặt mặc định
		music_enabled = true
		return
	
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		print("Không thể mở file cài đặt âm thanh")
		music_enabled = true
		return
	
	var content = file.get_as_text()
	file.close()
	
	var settings = JSON.parse_string(content)
	
	if settings == null or typeof(settings) != TYPE_DICTIONARY:
		print("Lỗi khi parse cài đặt âm thanh")
		music_enabled = true
		return
	
	music_enabled = settings.get("music_enabled", true)
	print("Đã tải cài đặt âm thanh: music_enabled = ", music_enabled)

# Hàm static để các scene khác có thể kiểm tra trạng thái âm nhạc
static func is_music_enabled() -> bool:
	var settings_path = "user://audio_settings.save"
	
	if not FileAccess.file_exists(settings_path):
		return true  # Mặc định bật âm nhạc
	
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return true
	
	var content = file.get_as_text()
	file.close()
	
	var settings = JSON.parse_string(content)
	if settings == null or typeof(settings) != TYPE_DICTIONARY:
		return true
	
	return settings.get("music_enabled", true)

func _on_close_button_pressed():
	"""Đóng option UI"""
	visible = false

func _input(event):
	"""Xử lý input để đóng option UI bằng ESC"""
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
