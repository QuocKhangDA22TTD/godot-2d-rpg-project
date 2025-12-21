extends Node2D

var cutscene_registry= {}
var played = {}

func _ready() -> void:
	register("intro", load("res://cutscene/intro.gd").new())
	register("intro_room", load("res://cutscene/intro_room.gd").new())

func register(name: String, scene: Node):
	cutscene_registry[name] = scene

func play(name: String):
	if name in played:
		return
	
	played[name] = true
	
	var cutscene = cutscene_registry[name]
	GameManager.state = GameManager.GameState.CUTSCENE
	
	get_tree().root.add_child(cutscene)
	
	await cutscene.play()
	
	GameManager.state = GameManager.GameState.GAMEPLAY
