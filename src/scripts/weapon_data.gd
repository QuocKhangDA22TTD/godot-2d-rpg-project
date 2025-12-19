extends Resource

class_name WeaponData

@export var name: String = "Sword"
@export var damage: int = 1
@export var knockback: float = 650.0

@export var hitbox_scene: PackedScene
@export var slash_effect_scene: PackedScene

@export var windup_time: float = 0.1
@export var active_time: float = 0.15
@export var recovery_time: float = 0.2
