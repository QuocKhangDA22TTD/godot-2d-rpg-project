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
