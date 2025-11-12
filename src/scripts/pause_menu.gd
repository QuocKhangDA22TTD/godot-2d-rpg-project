extends CanvasLayer

func _input(event: InputEvent):
	await get_tree().create_timer(0.05).timeout
	if get_tree().current_scene.name != "MainMenu":
		if event.is_action_pressed("esc") and !Global.player.inventory_ui.visible:
			self.visible = !self.visible
			get_tree().paused = !get_tree().paused
		elif event.is_action_pressed("esc") and Global.player.inventory_ui.visible:
			Global.player.inventory_ui.visible = false
			get_tree().paused = !get_tree().paused

func _on_resume_pressed() -> void:
	self.visible = !self.visible
	get_tree().paused = !get_tree().paused

func _on_quit_pressed() -> void:
	self.visible = !self.visible
	await GameManager.save_player_positon()
	get_tree().change_scene_to_packed(NavigationManager.scene_main_menu)
