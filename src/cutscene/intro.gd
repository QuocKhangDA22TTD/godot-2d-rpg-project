extends Node

var village_chief = load("res://scenes/npc/village_chief.tscn")
var village_chief_instance = null

func skip_to_end():
	"""Nhảy thẳng đến cuối cutscene với fade bình thường"""
	print("[Intro] Skipping to end...")
	
	# Fade to black bình thường
	var transition_anim = TransitionScreen.get_node("AnimationPlayer")
	transition_anim.speed_scale = 1.0  # Tốc độ bình thường
	TransitionScreen.transition()
	
	# Đợi fade hoàn thành
	await TransitionScreen.on_transition_finished
	
	# Đặt player về vị trí ban đầu
	if is_instance_valid(Global.player):
		Global.player.global_position = Vector2(808.0, 24.0 * 3.5)
	
	# Fade to normal
	await get_tree().create_timer(1.0).timeout
	
	# Reset trưởng làng thật trong scene về trạng thái mặc định
	reset_village_chief_to_default()
	
	# Force reset tất cả dialog UI trong scene
	force_reset_all_dialogs()
	
	# Đợi một chút để đảm bảo reset hoàn tất
	await get_tree().create_timer(0.5).timeout
	
	# Cleanup và kết thúc
	cleanup_and_finish()

func cleanup_and_finish():
	"""Cleanup tất cả và kết thúc cutscene"""
	print("[Intro] Starting cleanup...")
	
	# Reset player settings (luôn luôn thực hiện)
	if is_instance_valid(Global.player):
		Global.player.speed = 60.0
		Global.player.anima.speed_scale = 1.0
		Global.player.can_move = true
		print("[Intro] Player settings reset - can_move: ", Global.player.can_move)
		
		# Force reset player state để đảm bảo không bị stuck
		await get_tree().process_frame
		Global.player.can_move = true
		print("[Intro] Force reset player can_move: ", Global.player.can_move)
	else:
		print("[Intro] Global.player is invalid!")
	
	# Re-enable doors (luôn luôn thực hiện)
	enable_doors()
	
	# Xóa trưởng làng cutscene khỏi scene (luôn luôn thực hiện)
	if is_instance_valid(village_chief_instance):
		village_chief_instance.queue_free()
		village_chief_instance = null
		print("[Intro] Cutscene village chief removed")
	
	# Đảm bảo GameManager state được reset về GAMEPLAY
	GameManager.state = GameManager.GameState.GAMEPLAY
	print("[Intro] GameManager state reset to GAMEPLAY: ", GameManager.state)
	
	# Thêm một frame delay để đảm bảo tất cả thay đổi được áp dụng
	await get_tree().process_frame
	
	print("[Intro] Cutscene completed!")
	
	# Remove this cutscene from scene tree
	queue_free()

func reset_village_chief_to_default():
	"""Reset trưởng làng thật trong scene về trạng thái mặc định"""
	print("[Intro] Starting village chief reset...")
	
	# Tìm trưởng làng thật trong scene
	var main_map = get_tree().root.get_node("MainMap")
	if not main_map:
		print("[Intro] MainMap not found!")
		return
	
	print("[Intro] MainMap found, searching for village chief...")
	
	# Tìm trong tất cả children của MainMap
	var found_chief = _search_and_reset_chief(main_map)
	
	if not found_chief:
		print("[Intro] Village chief not found in scene tree!")
		# Debug: in ra tất cả children để kiểm tra
		print("[Intro] MainMap children:")
		for child in main_map.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
			if child.get_child_count() > 0:
				for grandchild in child.get_children():
					print("    - ", grandchild.name, " (", grandchild.get_class(), ")")
					if grandchild.get_child_count() > 0:
						for great_grandchild in grandchild.get_children():
							print("      - ", great_grandchild.name, " (", great_grandchild.get_class(), ")")

func _search_and_reset_chief(node: Node) -> bool:
	"""Tìm kiếm đệ quy và reset village chief"""
	# Kiểm tra node hiện tại - cải thiện logic kiểm tra
	if "npc_id" in node:
		print("[Intro] Checking node with npc_id: ", node.name, " - npc_id: ", node.npc_id)
		if node.npc_id == "trưởng làng":  # Sửa từ "village_chief" thành "trưởng làng"
			print("[Intro] Found village chief by npc_id: ", node.name)
			
			# Reset về branch "npc_default" (index 3) thay vì index 0
			node.current_branch_index = 3  # Branch "npc_default"
			node.current_state = "start"
			
			# Đảm bảo dialog manager được reset
			if node.has_method("set_dialog_state"):
				node.set_dialog_state("start")
			if node.has_method("set_dialog_tree"):
				node.set_dialog_tree(3)  # Set về branch "npc_default"
			
			# Reset dialog manager nếu có
			if node.has_node("DialogManager"):
				var dialog_manager = node.get_node("DialogManager")
				if dialog_manager.has_method("hide_dialog"):
					dialog_manager.hide_dialog()
				print("[Intro] Reset dialog manager for village chief")
			
			# Đảm bảo player có thể di chuyển lại
			if is_instance_valid(Global.player):
				Global.player.can_move = true
				print("[Intro] Restored player movement after village chief reset")
			
			print("[Intro] Reset village chief to npc_default branch - branch_index: ", node.current_branch_index, ", state: ", node.current_state)
			return true
	elif node.name.to_lower().contains("village") and node.name.to_lower().contains("chief"):
		print("[Intro] Found village chief by name: ", node.name)
		if "current_branch_index" in node:
			node.current_branch_index = 3  # Branch "npc_default"
			node.current_state = "start"
			# Đảm bảo dialog manager được reset
			if node.has_method("set_dialog_state"):
				node.set_dialog_state("start")
			if node.has_method("set_dialog_tree"):
				node.set_dialog_tree(3)
			
			# Reset dialog manager nếu có
			if node.has_node("DialogManager"):
				var dialog_manager = node.get_node("DialogManager")
				if dialog_manager.has_method("hide_dialog"):
					dialog_manager.hide_dialog()
				print("[Intro] Reset dialog manager for village chief")
			
			# Đảm bảo player có thể di chuyển lại
			if is_instance_valid(Global.player):
				Global.player.can_move = true
				print("[Intro] Restored player movement after village chief reset")
			
			print("[Intro] Reset village chief to npc_default branch (name) - branch_index: ", node.current_branch_index, ", state: ", node.current_state)
			return true
	
	# Tìm kiếm trong children
	for child in node.get_children():
		if _search_and_reset_chief(child):
			return true
	
	return false

func play():
	# Tạm thời disable door để tránh trigger nhầm trong cutscene
	disable_doors()
	
	# Tạo instance trưởng làng
	village_chief_instance = village_chief.instantiate()
	village_chief_instance.position = Vector2(808.0, 24.0 * 4)
	
	get_tree().root.get_node("MainMap").add_child(village_chief_instance)
	
	# Đợi _ready() chạy xong rồi mới set cutscene states
	await get_tree().create_timer(0.1).timeout
	
	# Set cutscene-specific states sau khi _ready() đã chạy
	village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
	village_chief_instance.current_branch_index = 0  # Branch "Chào hỏi mở đầu"
	village_chief_instance.set_dialog_tree(0)  # Đảm bảo set đúng branch
	village_chief_instance.set_dialog_state("Hỏi người chơi về nơi ở")
	
	print("[Intro] Village chief instance created with branch: ", village_chief_instance.current_branch_index, ", state: ", village_chief_instance.current_state)
	
	await get_tree().create_timer(0.9).timeout
	
	# Player di chuyển tới trưởng làng
	Global.player.speed = 30.0
	Global.player.anima.speed_scale = 0.75
	Global.player.anima.play("idle")
	Global.player.anima.play("run")
	await Global.player.move_to(Vector2(808.0, 24.0 * 3.5))
	Global.player.ray_cast_2d.target_position = Vector2(0, 1).normalized() * 15
	
	# Đợi một chút để raycast cập nhật
	await get_tree().create_timer(0.1).timeout
	Global.player.ray_cast_2d.force_raycast_update()
	
	var target = Global.player.ray_cast_2d.get_collider()
	
	# Nếu raycast không detect được, sử dụng trực tiếp village_chief_instance
	if not target and is_instance_valid(village_chief_instance):
		print("[Intro] Raycast failed to detect target, using direct reference")
		target = village_chief_instance
	
	print("[Intro] Target found: ", target.name if target else "null")
	print("[Intro] Target npc_id: ", target.npc_id if target and "npc_id" in target else "no npc_id")
	
	Global.player.can_move = false
	Global.player.anima.play("idle")
	
	await get_tree().create_timer(1.0).timeout
	
	# 1. Chào hỏi mở đầu - "Hỏi người chơi về nơi ở"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
		print("[Intro] Starting dialog 1 - State: ", village_chief_instance.current_state, ", Branch: ", village_chief_instance.current_branch_index)
		if target and is_instance_valid(target):
			print("[Intro] Calling start_dialog() on target: ", target.name)
			await target.start_dialog()
			print("[Intro] Waiting for dialog_finished signal...")
			await village_chief_instance.dialog_manager.dialog_finished
			print("[Intro] Dialog finished signal received!")
		else:
			print("[Intro] Target is null, skipping dialog 1")
	
	# 2. "Giới thiệu bản thân"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "Giới thiệu bản thân"
		print("[Intro] Starting dialog 2 - State: ", village_chief_instance.current_state, ", Branch: ", village_chief_instance.current_branch_index)
		if target and is_instance_valid(target):
			print("[Intro] Calling start_dialog() on target: ", target.name)
			await target.start_dialog()
			print("[Intro] Waiting for dialog_finished signal...")
			await village_chief_instance.dialog_manager.dialog_finished
			print("[Intro] Dialog finished signal received!")
		else:
			print("[Intro] Target is null, skipping dialog 2")
	
	# 3. "hướng dẫn bản đồ"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "hướng dẫn bản đồ"
		print("[Intro] Starting dialog 3 - State: ", village_chief_instance.current_state, ", Branch: ", village_chief_instance.current_branch_index)
		if target and is_instance_valid(target):
			print("[Intro] Calling start_dialog() on target: ", target.name)
			await target.start_dialog()
			await village_chief_instance.dialog_manager.dialog_finished
		else:
			print("[Intro] Target is null, skipping dialog 3")
	
	# === Chuyển đến NHÀ TRỌ (936, 280) - Tránh trigger door ===
	await transition_to_location(Vector2(936, 320), Vector2(936, 290))
	await get_tree().create_timer(0.5).timeout  # Thêm delay để đảm bảo position được cập nhật
	target = update_target()  # Cập nhật target sau transition
	
	# 4. "Nhà trọ"
	if is_instance_valid(village_chief_instance) and target and is_instance_valid(target):
		print("[Intro] Starting Nhà trọ dialog with target: ", target)
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Nhà trọ"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	else:
		print("[Intro] Cannot start Nhà trọ dialog - village_chief_instance: ", is_instance_valid(village_chief_instance), ", target: ", target)
	
	# === Chuyển đến HẦM NGỤC (1544, 702) - Tránh trigger door ===
	await transition_to_location(Vector2(1544, 720), Vector2(1544, 690))
	await get_tree().create_timer(0.5).timeout  # Thêm delay để đảm bảo position được cập nhật
	target = update_target()  # Cập nhật target sau transition
	
	# 5. "Hầm ngục"
	if is_instance_valid(village_chief_instance) and target and is_instance_valid(target):
		print("[Intro] Starting Hầm ngục dialog with target: ", target)
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Hầm ngục"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	else:
		print("[Intro] Cannot start Hầm ngục dialog - village_chief_instance: ", is_instance_valid(village_chief_instance), ", target: ", target)
	
	# === Chuyển đến KHU MUA BÁN (1128, 1120) ===
	await transition_to_location(Vector2(1128, 1120), Vector2(1128, 1090))
	await get_tree().create_timer(0.5).timeout  # Thêm delay để đảm bảo position được cập nhật
	target = update_target()  # Cập nhật target sau transition
	
	# 6. "Khu mua bán"
	if is_instance_valid(village_chief_instance) and target and is_instance_valid(target):
		print("[Intro] Starting Khu mua bán dialog with target: ", target)
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Khu mua bán"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	else:
		print("[Intro] Cannot start Khu mua bán dialog - village_chief_instance: ", is_instance_valid(village_chief_instance), ", target: ", target)
	
	# === Quay về vị trí ban đầu để kết thúc ===
	await transition_to_location(Vector2(808.0, 24.0 * 4), Vector2(808.0, 24.0 * 3.5))
	await get_tree().create_timer(0.5).timeout  # Thêm delay để đảm bảo position được cập nhật
	target = update_target()  # Cập nhật target sau transition
	
	# 7. "Tạm biệt"
	if is_instance_valid(village_chief_instance) and target and is_instance_valid(target):
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Tạm biệt"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	else:
		print("[Intro] Cannot start Tạm biệt dialog - village_chief_instance: ", is_instance_valid(village_chief_instance), ", target: ", target)
	
	# 8. "Lời kết"
	if is_instance_valid(village_chief_instance) and target and is_instance_valid(target):
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Lời kết"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	else:
		print("[Intro] Cannot start Lời kết dialog - village_chief_instance: ", is_instance_valid(village_chief_instance), ", target: ", target)
	
	# Kết thúc intro
	await get_tree().create_timer(1.0).timeout
	
	# Reset trưởng làng thật trong scene về trạng thái mặc định
	reset_village_chief_to_default()
	
	# Force reset tất cả dialog UI trong scene
	force_reset_all_dialogs()
	
	# Đợi một chút để đảm bảo reset hoàn tất
	await get_tree().create_timer(0.5).timeout
	
	# Cleanup và kết thúc
	cleanup_and_finish()

func update_target():
	"""Cập nhật target sau mỗi lần transition"""
	if not is_instance_valid(village_chief_instance):
		print("[Intro] Village chief invalid in update_target")
		return null
		
	if not is_instance_valid(Global.player):
		print("[Intro] Player invalid in update_target")
		return null
	
	# Tính toán hướng và cập nhật raycast
	var direction = (village_chief_instance.global_position - Global.player.global_position).normalized()
	Global.player.ray_cast_2d.target_position = direction * 15
	
	# Force update raycast
	Global.player.ray_cast_2d.force_raycast_update()
	
	var target = Global.player.ray_cast_2d.get_collider()
	
	print("[Intro] Player pos: ", Global.player.global_position)
	print("[Intro] Chief pos: ", village_chief_instance.global_position)
	print("[Intro] Direction: ", direction)
	print("[Intro] Raycast target: ", Global.player.ray_cast_2d.target_position)
	print("[Intro] Detected target: ", target)
	
	# Nếu raycast không detect được, thử trực tiếp
	if not target:
		print("[Intro] Raycast failed, using direct reference")
		return village_chief_instance
	
	return target

func transition_to_location(chief_pos: Vector2, player_pos: Vector2):
	"""Chuyển cảnh với fade effect và dịch chuyển nhân vật"""
	if not is_instance_valid(village_chief_instance):
		print("[Intro] Village chief instance is invalid!")
		return
		
	var transition_anim = TransitionScreen.get_node("AnimationPlayer")
	
	# Fade to black với tốc độ chậm
	transition_anim.speed_scale = 0.5
	TransitionScreen.transition()
	
	# Đợi signal transition finished
	await TransitionScreen.on_transition_finished
	
	# Dịch chuyển nhân vật (kiểm tra validity trước)
	if is_instance_valid(village_chief_instance):
		village_chief_instance.global_position = chief_pos
	
	if is_instance_valid(Global.player):
		Global.player.global_position = player_pos
	
	# Cập nhật hướng sprite của player
	if is_instance_valid(village_chief_instance) and is_instance_valid(Global.player):
		var direction = (village_chief_instance.global_position - Global.player.global_position).normalized()
		
		if direction.x < 0:
			Global.player.anima.flip_h = true
		else:
			Global.player.anima.flip_h = false
	
	# Đợi fade to normal hoàn thành
	await get_tree().create_timer(1.0).timeout
	
	# Reset tốc độ animation
	transition_anim.speed_scale = 1.0
	
	await get_tree().create_timer(0.5).timeout

func disable_doors():
	"""Tạm thời disable tất cả doors để tránh trigger nhầm trong cutscene"""
	var doors_node = get_tree().root.get_node("MainMap/Doors")
	if doors_node:
		for door in doors_node.get_children():
			if door is Door:
				door.monitoring = false
				print("[Intro] Disabled door: ", door.name)

func enable_doors():
	"""Re-enable tất cả doors sau khi cutscene kết thúc"""
	var doors_node = get_tree().root.get_node("MainMap/Doors")
	if doors_node:
		for door in doors_node.get_children():
			if door is Door:
				door.monitoring = true
				print("[Intro] Enabled door: ", door.name)

func force_reset_all_dialogs():
	"""Force reset tất cả dialog UI trong scene để tránh stuck"""
	print("[Intro] Force resetting all dialogs...")
	
	# Tìm tất cả DialogManager trong scene
	var main_map = get_tree().root.get_node("MainMap")
	if main_map:
		_reset_dialogs_recursive(main_map)
	
	# Reset tất cả dialog UI trong scene
	_reset_dialog_ui_recursive(get_tree().root)
	
	# Đảm bảo player có thể di chuyển
	if is_instance_valid(Global.player):
		Global.player.can_move = true
		print("[Intro] Force enabled player movement")

func _reset_dialogs_recursive(node: Node):
	"""Tìm kiếm đệ quy và reset tất cả dialog managers"""
	if node.name == "DialogManager" or node.get_class() == "DialogManager":
		print("[Intro] Found DialogManager: ", node.name)
		if node.has_method("hide_dialog"):
			node.hide_dialog()
			print("[Intro] Reset DialogManager: ", node.name)
	
	# Tìm kiếm trong children
	for child in node.get_children():
		_reset_dialogs_recursive(child)

func _reset_dialog_ui_recursive(node: Node):
	"""Tìm kiếm đệ quy và reset tất cả dialog UI"""
	if node.name == "DialogUI" or node.get_script() != null:
		var script_path = str(node.get_script().resource_path) if node.get_script() else ""
		if script_path.contains("dialog_ui.gd"):
			print("[Intro] Found DialogUI: ", node.name)
			if node.has_method("hide_dialog"):
				node.hide_dialog()
				print("[Intro] Reset DialogUI: ", node.name)
			
			# Đảm bảo CanvasLayer visible
			if node.has_node("CanvasLayer"):
				var canvas_layer = node.get_node("CanvasLayer")
				canvas_layer.visible = false  # Hide để reset
				canvas_layer.layer = 1  # Đặt layer thấp hơn skip UI
				print("[Intro] Reset CanvasLayer for DialogUI: ", node.name)
	
	# Tìm kiếm trong children
	for child in node.get_children():
		_reset_dialog_ui_recursive(child)
	
