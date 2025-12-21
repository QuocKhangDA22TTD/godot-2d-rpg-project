extends Node

var village_chief = load("res://scenes/npc/village_chief.tscn")
var village_chief_instance = null

func play():
	# Tạm thời disable door để tránh trigger nhầm trong cutscene
	disable_doors()
	
	# Tạo instance trưởng làng
	village_chief_instance = village_chief.instantiate()
	village_chief_instance.position = Vector2(808.0, 24.0 * 4)
	village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
	village_chief_instance.current_branch_index = 0  # Branch "Chào hỏi mở đầu"
	
	get_tree().root.get_node("MainMap").add_child(village_chief_instance)
	
	await get_tree().create_timer(1.0).timeout
	
	# Player di chuyển tới trưởng làng
	Global.player.speed = 30.0
	Global.player.anima.speed_scale = 0.75
	Global.player.anima.play("idle")
	Global.player.anima.play("run")
	await Global.player.move_to(Vector2(808.0, 24.0 * 3.5))
	Global.player.ray_cast_2d.target_position = Vector2(0, 1).normalized() * 15
	var target = Global.player.ray_cast_2d.get_collider()
	Global.player.can_move = false
	Global.player.anima.play("idle")
	
	await get_tree().create_timer(1.0).timeout
	
	# 1. Chào hỏi mở đầu - "Hỏi người chơi về nơi ở"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
		await target.start_dialog()
		print("[Intro] Waiting for dialog_finished signal...")
		await village_chief_instance.dialog_manager.dialog_finished
		print("[Intro] Dialog finished signal received!")
	
	# 2. "Giới thiệu bản thân"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "Giới thiệu bản thân"
		await target.start_dialog()
		print("[Intro] Waiting for dialog_finished signal...")
		await village_chief_instance.dialog_manager.dialog_finished
		print("[Intro] Dialog finished signal received!")
	
	# 3. "hướng dẫn bản đồ"
	if is_instance_valid(village_chief_instance):
		village_chief_instance.current_state = "hướng dẫn bản đồ"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	
	# === Chuyển đến NHÀ TRỌ (936, 280) - Tránh trigger door ===
	await transition_to_location(Vector2(936, 320), Vector2(936, 290))
	await get_tree().create_timer(0.5).timeout  # Thêm delay để đảm bảo position được cập nhật
	target = update_target()  # Cập nhật target sau transition
	
	# 4. "Nhà trọ"
	if is_instance_valid(village_chief_instance) and target:
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
	if is_instance_valid(village_chief_instance) and target:
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
	if is_instance_valid(village_chief_instance) and target:
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
	if is_instance_valid(village_chief_instance) and target:
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Tạm biệt"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	
	# 8. "Lời kết"
	if is_instance_valid(village_chief_instance) and target:
		village_chief_instance.set_dialog_state("start")  # Reset state
		village_chief_instance.current_state = "Lời kết"
		await target.start_dialog()
		await village_chief_instance.dialog_manager.dialog_finished
	
	# Kết thúc intro
	await get_tree().create_timer(1.0).timeout
	
	# Reset player speed
	Global.player.speed = 60.0
	Global.player.anima.speed_scale = 1.0
	Global.player.can_move = true
	
	# Re-enable doors
	enable_doors()
	
	# Xóa trưởng làng khỏi scene
	if is_instance_valid(village_chief_instance):
		village_chief_instance.queue_free()
		village_chief_instance = null
	
	print("[Intro] Cutscene completed!")

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
	
