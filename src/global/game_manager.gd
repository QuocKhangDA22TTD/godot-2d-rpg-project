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
		"coins": Global.player.coin_amount,
		"health": Global.player.health,
		"max_health": Global.player.max_health
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

func save_inventory(inventory_list: Array) -> bool:
	"""Lưu inventory vào file"""
	var inventory_data = []
	
	for item in inventory_list:
		if item != null:
			var item_save = {
				"item_type": item["item_type"],
				"item_name": item["item_name"],
				"item_effect": item["item_effect"],
				"quantity": item["quantity"],
				"scene_path": item["scene_path"]
			}
			inventory_data.append(item_save)
		else:
			inventory_data.append(null)
	
	var file = FileAccess.open("user://inventory.save", FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(inventory_data)
		file.store_string(json_data)
		file.close()
		print("Lưu inventory thành công")
		return true
	else:
		print("Lưu inventory thất bại")
		return false

func load_inventory() -> Array:
	"""Tải inventory từ file"""
	var inventory_save_path = "user://inventory.save"
	
	if not FileAccess.file_exists(inventory_save_path):
		print("Không tìm thấy file inventory.save")
		return []
	
	var file = FileAccess.open(inventory_save_path, FileAccess.READ)
	if file == null:
		print("Không thể mở file inventory.save")
		return []
	
	var content = file.get_as_text()
	file.close()
	
	var inventory_data = JSON.parse_string(content)
	
	if inventory_data == null:
		print("Lỗi khi parse inventory data")
		return []
	
	if typeof(inventory_data) != TYPE_ARRAY:
		print("Inventory data không phải array")
		return []
	
	# Khôi phục inventory từ data
	var loaded_inventory = []
	for item_data in inventory_data:
		if item_data != null:
			var item = {
				"item_type": item_data["item_type"],
				"item_name": item_data["item_name"],
				"item_effect": item_data["item_effect"],
				"quantity": item_data["quantity"],
				"scene_path": item_data["scene_path"],
				"item_texture": get_item_texture(item_data["item_name"])  # 👈 Khôi phục texture
			}
			loaded_inventory.append(item)
		else:
			loaded_inventory.append(null)
	
	print("Inventory tải thành công: ", loaded_inventory.size(), " slots")
	return loaded_inventory

func get_item_texture(item_name: String) -> Texture:
	"""Khôi phục texture dựa trên tên item"""
	# Tạo AtlasTexture cho items từ items.png
	var items_texture = preload("res://assets/sprites/items.png")
	
	match item_name:
		"Than đá":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = items_texture
			atlas_texture.region = Rect2(24, 0, 24, 24)  # Than đá
			return atlas_texture
		"Bình máu":
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = items_texture
			atlas_texture.region = Rect2(0, 0, 24, 24)  # Bình máu
			return atlas_texture
		_:
			# Item không xác định, trả về null
			print("Cảnh báo: Item '", item_name, "' không có texture định nghĩa")
			return null

func load_game():
	if not FileAccess.file_exists(save_path):
		var default_data = {
			"scene": "res://scenes/map/main_map.tscn",
			"x": 808.0,
			"y": 24.0,
			"health": 5.0,
			"max_health": 5.0,
			"coins": 0
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

func get_item_effect_display_name(effect_code: String) -> String:
	"""Convert item effect code to display name"""
	match effect_code:
		"heal":
			return "Hồi máu"
		"":
			return "Không có hiệu ứng"
		_:
			return effect_code

func save_game(data):
	var json = JSON.stringify(data)
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_string(json)
	file.close()

func reset_all_game_data():
	"""Xóa toàn bộ dữ liệu game và tạo dữ liệu mặc định mới"""
	print("Đang reset toàn bộ dữ liệu game...")
	
	# Xóa các file save
	var save_files = [
		"user://savegame.save",
		"user://inventory.save", 
		"user://quests.save"
	]
	
	for file_path in save_files:
		if FileAccess.file_exists(file_path):
			var dir = DirAccess.open("user://")
			if dir:
				dir.remove(file_path.get_file())
				print("Đã xóa file: ", file_path)
	
	# Reset inventory trong Global
	Global.inventory.clear()
	Global.inventory.resize(24)
	
	# Reset player reference
	if Global.player:
		Global.player = null
	
	# Reset game manager state
	game_over = false
	
	# Tạo dữ liệu player mặc định
	var default_player_data = {
		"scene": "res://scenes/map/main_map.tscn",
		"x": 808.0,
		"y": 24.0,
		"health": 5.0,
		"max_health": 5.0,
		"coins": 0
	}
	
	# Lưu dữ liệu mặc định
	save_game(default_player_data)
	save_inventory(Global.inventory)
	
	print("Đã reset toàn bộ dữ liệu game thành công!")
