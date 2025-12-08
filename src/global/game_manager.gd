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
		"scene": Global.player.get_tree().current_scene.scene_file_path,
		"coins": Global.player.coin_amount
	}

	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)

	if file:
		var json_data = JSON.stringify(data)
		file.store_string(json_data)
		file.close()
		print("Lưu trạng thái player thành công")
		return true
	else:
		print("Lưu trạng thái player thất bại")
		return false

func save_quests(quests: Dictionary):
	"""Lưu tất cả quest hiện tại vào file"""
	var quest_data = {}
	
	for quest_id in quests:
		var quest = quests[quest_id]
		quest_data[quest_id] = {
			"quest_id": quest.quest_id,
			"quest_name": quest.quest_name,
			"quest_description": quest.quest_description,
			"state": quest.state,
			"unlock_id": quest.unlock_id,
			"is_repeatable": quest.is_repeatable,
			"objectives": [],
			"rewards": []
		}
		
		# Lưu thông tin objectives
		for objective in quest.objectives:
			quest_data[quest_id]["objectives"].append({
				"id": objective.id,
				"description": objective.description,
				"target_type": objective.target_type,
				"target_id": objective.target_id,
				"objective_dialog": objective.objective_dialog,
				"required_quantity": objective.required_quantity,
				"collected_quantity": objective.collected_quantity,
				"is_completed": objective.is_completed
			})
		
		# Lưu thông tin rewards
		for reward in quest.rewards:
			quest_data[quest_id]["rewards"].append({
				"reward_type": reward.reward_type,
				"reward_amount": reward.reward_amount
			})
	
	var file = FileAccess.open("user://quests.save", FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(quest_data)
		file.store_string(json_data)
		file.close()
		print("Quest lưu thành công")
		return true
	else:
		print("Lưu quest thất bại")
		return false

func load_quests() -> Dictionary:
	"""Tải lại quest đã lưu từ file"""
	var quests_save_path = "user://quests.save"
	
	if not FileAccess.file_exists(quests_save_path):
		print("Không tìm thấy file quests.save - trả về dictionary rỗng")
		return {}
	
	var file = FileAccess.open(quests_save_path, FileAccess.READ)
	if file == null:
		print("Không thể mở file quests.save")
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var quest_data = JSON.parse_string(content)
	
	if quest_data == null or typeof(quest_data) != TYPE_DICTIONARY:
		print("Lỗi khi parse quest data")
		return {}
	
	print("Quest tải thành công: ", quest_data.keys())
	return quest_data

func load_game():
	if not FileAccess.file_exists(save_path):
		var default_data = {
			"scene": "res://scenes/map/main_map.tscn",
			"x": 808.0,
			"y": 24.0
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
