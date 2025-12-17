extends Node

var sfx_players = []
var sfx_index = 0

var sfx = {}
var ui = {}
var music = {}

#@onready var sfx_player = $SFXPlayer
@onready var ui_player = $UIPlayer
@onready var music_player = $MusicPlayer

func _ready() -> void:
	print("[AudioManager] Khởi tạo AudioManager...")
	
	# Load audio resources
	sfx["slash"] = preload("res://assets/audio/sfx/sword_sound_edit.wav")
	sfx["hit"] = preload("res://assets/audio/sfx/hit_edit.wav")
	sfx["dirt_footstep"] = preload("res://assets/audio/sfx/dirt_footstep_edit.wav")
	sfx["player_damaged"] = preload("res://assets/audio/sfx/player_damaged_edit.wav")
	sfx["open_dialog"] = preload("res://assets/audio/sfx/open_dialog_edit.wav")
	sfx["pick_up_item"] = preload("res://assets/audio/sfx/pick_up_item_edit.wav")
	# Thêm nhạc menu (sử dụng cùng nhạc village_1 hoặc có thể thêm nhạc riêng)
	music["village_1"] = preload("res://assets/audio/music/background_music_village_1.wav")
	music["menu"] = preload("res://assets/audio/music/background_music_village_1.wav")
	
	# Khởi tạo SFX players
	sfx_players = [
		$SFXPlayers/SFX1,
		$SFXPlayers/SFX2,
		$SFXPlayers/SFX3
	]
	
	# Kiểm tra các node có tồn tại không
	if music_player == null:
		print("Lỗi: MusicPlayer node không tồn tại!")
	else:
		print("[AudioManager] MusicPlayer đã sẵn sàng")
	
	if ui_player == null:
		print("Lỗi: UIPlayer node không tồn tại!")
	else:
		print("[AudioManager] UIPlayer đã sẵn sàng")
	
	for i in range(sfx_players.size()):
		if sfx_players[i] == null:
			print("Lỗi: SFX Player ", i, " không tồn tại!")
		else:
			print("[AudioManager] SFX Player ", i, " đã sẵn sàng")
	
	print("[AudioManager] Khởi tạo hoàn tất. Music enabled: ", is_music_enabled())

func play_sfx(name: String) -> void:
	if not sfx.has(name):
		print("Không tìm thấy sfx: " + name)
		return
	
	if sfx_players.is_empty():
		print("Cảnh báo: sfx_players rỗng")
		return
	
	var player = sfx_players[sfx_index]
	if player == null:
		print("Cảnh báo: SFX player là null")
		return
		
	sfx_index = (sfx_index + 1) % sfx_players.size()
	
	if player.stream == sfx[name] and player.playing:
		return
	
	player.stream = sfx[name]
	player.pitch_scale = randf_range(0.75, 1.25)
	player.play()

func play_music(name: String, loop: bool = true) -> void:
	# Kiểm tra xem music_player có tồn tại không
	if music_player == null:
		print("Cảnh báo: music_player là null")
		return
	
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
	if music_player == null:
		print("Cảnh báo: music_player là null trong _on_music_finished")
		return
		
	if music_player.stream:
		music_player.play()

func stop_music() -> void:
	"""Dừng phát nhạc nền"""
	if music_player == null:
		print("Cảnh báo: music_player là null")
		return
		
	if music_player.playing:
		music_player.stop()
	music_player.stream = null
	
	# Ngắt kết nối signal nếu có
	if music_player.is_connected("finished", Callable(self, "_on_music_finished")):
		music_player.disconnect("finished", Callable(self, "_on_music_finished"))

func pause_music() -> void:
	"""Tạm dừng nhạc nền"""
	if music_player == null:
		print("Cảnh báo: music_player là null")
		return
		
	if music_player.playing:
		music_player.stream_paused = true

func resume_music() -> void:
	"""Tiếp tục phát nhạc nền"""
	if music_player == null:
		print("Cảnh báo: music_player là null")
		return
		
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

func is_ready() -> bool:
	"""Kiểm tra xem AudioManager đã sẵn sàng chưa"""
	return music_player != null and ui_player != null and not sfx_players.is_empty()

func get_status() -> String:
	"""Lấy trạng thái hiện tại của AudioManager"""
	var status = "AudioManager Status:\n"
	status += "- Music Player: " + ("OK" if music_player != null else "NULL") + "\n"
	status += "- UI Player: " + ("OK" if ui_player != null else "NULL") + "\n"
	status += "- SFX Players: " + str(sfx_players.size()) + " players\n"
	status += "- Music Enabled: " + str(is_music_enabled()) + "\n"
	if music_player != null:
		status += "- Music Playing: " + str(music_player.playing) + "\n"
		status += "- Current Stream: " + (str(music_player.stream) if music_player.stream else "None")
	return status
