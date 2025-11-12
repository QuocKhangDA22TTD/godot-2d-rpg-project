extends Area2D
class_name Door

@export var destination_level_tag: String
@export var destiation_door_tag: String

@onready var spawn = $Spawn

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		NavigationManager.go_to_level(destination_level_tag, destiation_door_tag)
