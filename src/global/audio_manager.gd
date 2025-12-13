extends Node

var sfx = {}
var ui = {}
var music = {}

@onready var sfx_player = $SFXPlayer
@onready var ui_player = $UIPlayer
@onready var music_player = $MusicPlayer

func _ready() -> void:
	sfx["slash"] = preload("res://assets/audio/sfx/sword_sound_edit.wav")
	sfx["hit"] = preload("res://assets/audio/sfx/hit_edit.wav")
	music["village_1"] = preload("res://assets/audio/music/background_music_village_1.wav")
	# Thêm nhạc menu (sử dụng cùng nhạc village_1 hoặc có thể thêm nhạc riêng)
	music["menu"] = preload("res://assets/audio/music/background_music_village_1.wav")
	
	music.stream = null

func play_sfx(name: String) -> void:
	if not sfx.has(name):
		print("Không tìm thấy sfx: " + name)
		return
	if sfx_player.stream == sfx[name] and sfx_player.playing:
		return
	
	sfx_player.stream = sfx[name]
	sfx_player.play()

func play_music(name: String, loop: bool = true) -> void:
	# Kiểm tra xem âm nhạc có được bật không
	if not is_music_enabled():
		return
		
	if not music.has(name):
		print("Không tìm thấy music background: " + name)
		return
		
	if music_player.stream == music[name] and music_player.playing:
		return
	
	music_player.stream = music[name]
	music_player.stop()
	music_player.stream_paused = false
	music_player.play()
	
	if loop:
		music_player.connect("finished", Callable(self, "_on_music_finished"))

func _on_music_finished() -> void:
	if music_player.stream:
		music_player.play()

func stop_music() -> void:
	"""Dừng phát nhạc nền"""
	if music_player.playing:
		music_player.stop()
	music_player.stream = null
	
	# Ngắt kết nối signal nếu có
	if music_player.is_connected("finished", Callable(self, "_on_music_finished")):
		music_player.disconnect("finished", Callable(self, "_on_music_finished"))

func pause_music() -> void:
	"""Tạm dừng nhạc nền"""
	if music_player.playing:
		music_player.stream_paused = true

func resume_music() -> void:
	"""Tiếp tục phát nhạc nền"""
	if music_player.stream and music_player.stream_paused:
		music_player.stream_paused = false

func is_music_enabled() -> bool:
	"""Kiểm tra xem âm nhạc có được bật không"""
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
