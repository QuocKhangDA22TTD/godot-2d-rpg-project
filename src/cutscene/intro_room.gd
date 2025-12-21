extends Node

var village_chief = load("res://scenes/npc/village_chief.tscn")

func play():
	# VÔ HIỆU HÓA TẠM THỜI - Tập trung vào cutscene intro.gd trước
	print("[IntroRoom] Cutscene disabled temporarily")
	return
	
	# Code cũ được comment out
	"""
	var village_chief_instance = village_chief.instantiate()
	village_chief_instance.position = Vector2(468.0, 472.0)
	get_tree().root.get_node("Indoor").add_child(village_chief_instance)
	
	Global.player.global_position = Vector2(480.0, 472.0)
	Global.player.anima.flip_h = true
	
	Global.player.ray_cast_2d.target_position = Vector2(-1,0).normalized() * 15
	await get_tree().create_timer(1.0).timeout
	
	var target = Global.player.ray_cast_2d.get_collider()
	Global.player.can_move = false
	
	village_chief_instance.current_branch_index = 1
	
	village_chief_instance.current_state = "Nói về căn phòng"
	await target.start_dialog()
	await get_tree().create_timer(8.0).timeout
	
	village_chief_instance.dialog_manager.hide_dialog()
	await get_tree().create_timer(3.0).timeout
	TransitionScreen.get_node("AnimationPlayer").speed_scale = 0.25
	await NavigationManager.go_to_level("in_door", "Indoor")
	TransitionScreen.get_node("AnimationPlayer").speed_scale = 1.0
	"""
