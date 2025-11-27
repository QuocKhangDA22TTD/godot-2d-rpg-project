extends Node

var scene_main_menu = preload("res://scenes/ui/main_menu.tscn")
var scene_main_map = preload("res://scenes/map/main_map.tscn")
var scene_level_1 = preload("res://scenes/map/level_1.tscn")
var in_door = preload("res://scenes/map/indoor.tscn")

signal on_trigger_player_spawn

var spawn_door_tag

func go_to_level(level_tag, destination_tag):
	var scene_to_load
	
	match level_tag:
		"main_map":
			scene_to_load = scene_main_map
		"level_1":
			scene_to_load = scene_level_1
		"in_door":
			scene_to_load = in_door
	
	if scene_to_load != null:
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		spawn_door_tag = destination_tag
		get_tree().change_scene_to_packed(scene_to_load)

func trigger_player_spawn(positon: Vector2):
	on_trigger_player_spawn.emit(positon)
