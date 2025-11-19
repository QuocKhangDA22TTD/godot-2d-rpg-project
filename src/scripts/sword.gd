extends Node2D

@onready var anim_player = $AnimationPlayer
var damage = 2.0
var force = 200

func _ready():
	visible = false

func _input(event: InputEvent) -> void:
	if get_tree().paused or Global.player.can_move == false:
		return
	if event.is_action_pressed("slash"):
		if not anim_player.is_playing() or anim_player.current_animation != "slash_left":
			anim_player.play("left_slash")
			visible = true
			Global.facing = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "left_slash":
		anim_player.play("left_return")
		visible = false
		Global.facing = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		print("danh trung")
		body.get_damaged(damage)
		body.knockback_force = (body.global_position - Global.player.global_position).normalized() * force
