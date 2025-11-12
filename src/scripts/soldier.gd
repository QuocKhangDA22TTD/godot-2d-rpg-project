extends Node2D

@onready var anim = $AnimatedSprite2D
@export var is_flip_h = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.flip_h = is_flip_h


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
