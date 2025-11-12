extends Control

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_start_game_pressed() -> void:
	var game_data = GameManager.load_game()
	var scene = game_data["scene"]
	var load_scene = load(scene)
	get_tree().paused = false
	get_tree().change_scene_to_packed(load_scene)
