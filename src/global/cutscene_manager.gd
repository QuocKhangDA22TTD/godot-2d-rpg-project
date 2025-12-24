extends Node2D

var cutscene_registry = {}
var played = {}
var save_path = "user://cutscenes.save"

# Skip cutscene UI
var skip_ui = null
var current_cutscene = null
var skip_requested = false

func _ready() -> void:
	# Không tạo instances ngay, chỉ register tên
	cutscene_registry["intro"] = "intro"
	cutscene_registry["intro_room"] = "intro_room"
	
	# Load cutscene state từ file
	load_cutscene_state()
	
	# Create skip UI
	create_skip_ui()
	
	print("[CutsceneManager] Initialized with ", cutscene_registry.size(), " cutscenes")

func create_skip_ui():
	"""Tạo UI skip cutscene"""
	skip_ui = CanvasLayer.new()
	skip_ui.name = "CutsceneSkipUI"
	skip_ui.layer = 50  # Giảm layer để không che khuất dialog UI (dialog UI thường dùng layer 1-10)
	
	# Container
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Không chặn mouse events
	skip_ui.add_child(container)
	
	# Background panel for visibility
	var bg_panel = Panel.new()
	bg_panel.anchor_left = 1.0
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_top = 0.0
	bg_panel.anchor_bottom = 0.0
	bg_panel.offset_left = -95
	bg_panel.offset_right = -5
	bg_panel.offset_top = 5
	bg_panel.offset_bottom = 45
	bg_panel.modulate = Color(0, 0, 0, 0.7)  # Semi-transparent black background
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg_panel)
	
	# Skip button - nhỏ hơn và ở góc trên bên phải
	var skip_button = Button.new()
	skip_button.text = "Skip"
	skip_button.size = Vector2(80, 30)  # Lớn hơn một chút để dễ thấy
	
	# Đặt ở góc trên bên phải (cách mép 10px)
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_top = 0.0
	skip_button.anchor_bottom = 0.0
	skip_button.offset_left = -90  # -80 - 10 margin
	skip_button.offset_right = -10
	skip_button.offset_top = 10
	skip_button.offset_bottom = 40
	
	# Style the button to make it more visible
	skip_button.modulate = Color.WHITE  # Đảm bảo màu trắng
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.add_theme_color_override("font_color_hover", Color.YELLOW)
	skip_button.add_theme_color_override("font_color_pressed", Color.GRAY)
	skip_button.add_theme_font_size_override("font_size", 14)
	
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Chỉ button mới nhận mouse events
	skip_button.pressed.connect(_on_skip_pressed)
	container.add_child(skip_button)
	
	# Hide by default
	skip_ui.visible = false
	
	print("[CutsceneManager] Skip UI created successfully with layer: ", skip_ui.layer)

func register(name: String, scene: Node):
	cutscene_registry[name] = scene

func get_fresh_cutscene(name: String) -> Node:
	"""Tạo instance mới của cutscene để tránh reuse freed objects"""
	match name:
		"intro":
			return load("res://cutscene/intro.gd").new()
		"intro_room":
			return load("res://cutscene/intro_room.gd").new()
		_:
			print("[CutsceneManager] Unknown cutscene: ", name)
			return null

func play(name: String, force_replay: bool = false):
	if name in played and not force_replay:
		print("[CutsceneManager] Cutscene '", name, "' already played, skipping")
		return
	
	print("[CutsceneManager] Playing cutscene: ", name)
	if not force_replay:
		played[name] = true
		# Lưu state ngay lập tức
		save_cutscene_state()
	
	# Tạo fresh instance để tránh reuse freed objects
	var cutscene = get_fresh_cutscene(name)
	if cutscene == null:
		print("[CutsceneManager] Failed to create cutscene: ", name)
		return
	
	current_cutscene = cutscene
	skip_requested = false
	
	GameManager.state = GameManager.GameState.CUTSCENE
	
	# Show skip UI
	if skip_ui and not skip_ui.is_inside_tree():
		get_tree().root.add_child(skip_ui)
	skip_ui.visible = true
	print("[CutsceneManager] Skip UI shown - Layer: ", skip_ui.layer, " Visible: ", skip_ui.visible)
	print("[CutsceneManager] Skip UI children count: ", skip_ui.get_children().size())
	
	# Add cutscene to scene
	get_tree().root.add_child(cutscene)
	
	# Start cutscene
	if cutscene.has_method("play"):
		cutscene.play()
	
	# Wait for cutscene to finish hoặc skip được request
	while is_instance_valid(cutscene) and cutscene.is_inside_tree() and not skip_requested:
		await get_tree().process_frame
	
	# Nếu skip được request, gọi hàm skip của cutscene
	if skip_requested and is_instance_valid(cutscene):
		if cutscene.has_method("skip_to_end"):
			print("[CutsceneManager] Skipping to end of cutscene...")
			cutscene.skip_to_end()
			# Đợi cutscene tự kết thúc
			while is_instance_valid(cutscene) and cutscene.is_inside_tree():
				await get_tree().process_frame
		else:
			# Nếu không có skip_to_end method, force cleanup
			print("[CutsceneManager] Cutscene doesn't have skip_to_end, force cleanup")
			if cutscene.is_inside_tree():
				cutscene.queue_free()
	
	# Cleanup
	current_cutscene = null
	if skip_ui and skip_ui.is_inside_tree():
		skip_ui.visible = false
		skip_ui.get_parent().remove_child(skip_ui)
	
	# Force reset tất cả dialog UI để tránh conflicts
	force_reset_all_dialog_systems()
	
	# Đảm bảo GameManager state được reset về GAMEPLAY
	GameManager.state = GameManager.GameState.GAMEPLAY
	
	# Đảm bảo player có thể di chuyển
	if is_instance_valid(Global.player):
		Global.player.can_move = true
		print("[CutsceneManager] Player can_move restored: ", Global.player.can_move)
	
	print("[CutsceneManager] Cutscene finished, returning to gameplay - GameManager.state: ", GameManager.state)
	
	# Lưu lại state sau khi hoàn thành (chỉ khi không phải force replay)
	if not force_replay:
		save_cutscene_state()

func _input(event):
	"""Handle skip input"""
	if GameManager.state == GameManager.GameState.CUTSCENE:
		if event.is_action_pressed("esc"):
			_on_skip_pressed()

func _on_skip_pressed():
	"""Xử lý khi bấm skip"""
	if GameManager.state == GameManager.GameState.CUTSCENE and current_cutscene:
		skip_requested = true
		print("[CutsceneManager] Skip requested for cutscene: ", current_cutscene.name if current_cutscene else "unknown")

func save_cutscene_state():
	"""Lưu trạng thái cutscene đã play vào file"""
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(played)
		file.store_string(json_data)
		file.close()
		print("[CutsceneManager] Saved cutscene state: ", played)
		return true
	else:
		print("[CutsceneManager] Failed to save cutscene state")
		return false

func load_cutscene_state():
	"""Load trạng thái cutscene từ file"""
	if not FileAccess.file_exists(save_path):
		print("[CutsceneManager] No cutscene save file found, starting fresh")
		played = {}
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("[CutsceneManager] Failed to open cutscene save file")
		played = {}
		return
	
	var content = file.get_as_text()
	file.close()
	
	var parsed_data = JSON.parse_string(content)
	if parsed_data != null and typeof(parsed_data) == TYPE_DICTIONARY:
		played = parsed_data
		print("[CutsceneManager] Loaded cutscene state: ", played)
	else:
		print("[CutsceneManager] Failed to parse cutscene save file")
		played = {}

func reset_cutscene_state():
	"""Reset tất cả cutscene state (dùng cho new game)"""
	played = {}
	save_cutscene_state()
	print("[CutsceneManager] Reset all cutscene state")

func is_cutscene_played(name: String) -> bool:
	"""Kiểm tra xem cutscene đã được play chưa"""
	return name in played

func mark_cutscene_played(name: String):
	"""Đánh dấu cutscene đã được play (không thực sự play)"""
	played[name] = true
	save_cutscene_state()
	print("[CutsceneManager] Marked cutscene as played: ", name)

func test_cutscene_system():
	"""Test function để kiểm tra hệ thống cutscene"""
	print("[CutsceneManager] Testing cutscene system...")
	print("[CutsceneManager] Available cutscenes: ", cutscene_registry.keys())
	print("[CutsceneManager] Played cutscenes: ", played.keys())
	print("[CutsceneManager] Skip UI created: ", skip_ui != null)
	print("[CutsceneManager] Current game state: ", GameManager.state)
	
	# Test skip UI
	if skip_ui:
		print("[CutsceneManager] Skip UI layer: ", skip_ui.layer)
		print("[CutsceneManager] Skip UI visible: ", skip_ui.visible)
		print("[CutsceneManager] Skip UI children: ", skip_ui.get_children().size())

func force_play_intro():
	"""Force play intro cutscene for testing"""
	print("[CutsceneManager] Force playing intro cutscene...")
	await play("intro", true)

func force_reset_all_dialog_systems():
	"""Force reset tất cả dialog system trong game để tránh conflicts"""
	print("[CutsceneManager] Force resetting all dialog systems...")
	
	# Reset tất cả dialog UI và manager trong scene tree
	_reset_all_dialogs_recursive(get_tree().root)
	
	# Đảm bảo player có thể di chuyển
	if is_instance_valid(Global.player):
		Global.player.can_move = true
		print("[CutsceneManager] Force enabled player movement")

func _reset_all_dialogs_recursive(node: Node):
	"""Tìm kiếm đệ quy và reset tất cả dialog systems"""
	# Reset DialogManager
	if node.name == "DialogManager" or node.get_class() == "DialogManager":
		print("[CutsceneManager] Found DialogManager: ", node.name)
		if node.has_method("hide_dialog"):
			node.hide_dialog()
			print("[CutsceneManager] Reset DialogManager: ", node.name)
	
	# Reset DialogUI
	if node.name == "DialogUI" or (node.get_script() != null and str(node.get_script().resource_path).contains("dialog_ui.gd")):
		print("[CutsceneManager] Found DialogUI: ", node.name)
		if node.has_method("hide_dialog"):
			node.hide_dialog()
			print("[CutsceneManager] Reset DialogUI: ", node.name)
		
		# Đảm bảo CanvasLayer được reset
		if node.has_node("CanvasLayer"):
			var canvas_layer = node.get_node("CanvasLayer")
			canvas_layer.visible = false  # Hide để reset
			canvas_layer.layer = 1  # Đặt layer thấp
			print("[CutsceneManager] Reset CanvasLayer for DialogUI: ", node.name)
	
	# Reset NPCs - sử dụng npc_id đúng từ JSON và reset về branch thích hợp
	if "npc_id" in node:
		print("[CutsceneManager] Found NPC: ", node.name, " - npc_id: ", node.npc_id)
		
		# Reset về branch thích hợp cho từng NPC
		var target_branch_index = 0
		if node.npc_id == "trưởng làng":
			target_branch_index = 3  # Branch "npc_default"
		elif node.npc_id == "hội trưởng":
			target_branch_index = 0  # Branch "nhận nhiệm vụ"
		elif node.npc_id == "người bán hàng":
			target_branch_index = 0  # Branch "Chào Hỏi"
		elif node.npc_id == "lính canh":
			target_branch_index = 0  # Branch "npc_default"
		
		if node.has_method("set_dialog_state"):
			node.set_dialog_state("start")
		if node.has_method("set_dialog_tree"):
			node.set_dialog_tree(target_branch_index)
		node.current_state = "start"
		node.current_branch_index = target_branch_index
		
		# Reset dialog manager của NPC
		if node.has_node("DialogManager"):
			var dialog_manager = node.get_node("DialogManager")
			if dialog_manager.has_method("hide_dialog"):
				dialog_manager.hide_dialog()
		
		print("[CutsceneManager] Reset NPC: ", node.name, " to branch index: ", target_branch_index)
	
	# Tìm kiếm trong children
	for child in node.get_children():
		_reset_all_dialogs_recursive(child)
