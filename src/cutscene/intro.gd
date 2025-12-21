extends Node

var village_chief = load("res://scenes/npc/village_chief.tscn")

func play():
	var village_chief_instance = village_chief.instantiate()
	village_chief_instance.position = Vector2(808.0, 24.0 * 4)
	village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
	
	get_tree().root.get_node("MainMap").add_child(village_chief_instance)
	
	await get_tree().create_timer(1.0).timeout
	
	Global.player.speed = 30.0
	Global.player.anima.speed_scale = 0.75
	Global.player.anima.play("idle")
	Global.player.anima.play("run")
	await Global.player.move_to(Vector2(808.0, 24.0 * 3.5))
	Global.player.ray_cast_2d.target_position = Vector2(0,1).normalized() * 15
	var target = Global.player.ray_cast_2d.get_collider()
	Global.player.can_move = false
	Global.player.anima.play("idle")
	
	await get_tree().create_timer(3.0).timeout
	
	village_chief_instance.current_state = "Hỏi người chơi về nơi ở"
	await target.start_dialog()
	await get_tree().create_timer(3.0).timeout
	
	village_chief_instance.current_state = "Giới thiệu bản thân"
	await target.start_dialog()
	await get_tree().create_timer(3.0).timeout
	
	village_chief_instance.current_state = "Chỉ chỗ trọ"
	await target.start_dialog()
	await get_tree().create_timer(2.0).timeout
	
	village_chief_instance.dialog_manager.hide_dialog()
	await get_tree().create_timer(2.0).timeout
	TransitionScreen.get_node("AnimationPlayer").speed_scale = 0.5
	await NavigationManager.go_to_level("in_door", "Indoor")
	TransitionScreen.get_node("AnimationPlayer").speed_scale = 1.0
	
