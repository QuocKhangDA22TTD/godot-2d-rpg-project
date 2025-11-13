extends Node

var player_scene = preload("res://scenes/player/player.tscn")
var player = null
var game_over = false

var save_path = "user://savegame.save"

func spawn_player(map: Node):
	if player == null or not player.is_inside_tree():
		if player != null:
			player.queue_free()
			player = null
		player = player_scene.instantiate()
		if map != null and map.is_inside_tree():
			map.add_child(player)
			Global.player.died.connect(_on_player_died)
		else:
			print("Map không hợp lệ hoặc chưa sẵn sàng để thêm player")
	else:
		print("Player đã tồn tại trong scene tree")

func save_player_positon():
	var data = {
		"x": Global.player.global_position.x,
		"y": Global.player.global_position.y,
		"scene": Global.player.get_tree().current_scene.scene_file_path
	}
	
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	
	if file:
		var json_data = JSON.stringify(data)
		file.store_string(json_data)
		file.close()
		print("luu thanh cong")
	print("luu that bai")

func load_game():
	if not FileAccess.file_exists(save_path):
		var default_data = {
			"scene": "res://scenes/map/main_map.tscn",
			"x": 200.0,
			"y": 200.0
		}
		save_game(default_data)
	
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var result = JSON.parse_string(content)
	if typeof(result) == TYPE_DICTIONARY:
		return result

func _on_player_died():
	game_over = true

func save_game(data):
	var json = JSON.stringify(data)
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_string(json)
	file.close()
