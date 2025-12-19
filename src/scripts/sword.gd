extends Node2D

@onready var anim_player = $AnimationPlayer
var damage = 2.0
var force = 200
var direction = Vector2.ZERO
var knockback = 120.0

#func _ready():
	#visible = false
#
#func _input(event: InputEvent) -> void:
	#if get_tree().paused or Global.player.can_move == false:
		#return
	#if event.is_action_pressed("slash"):
		#if not anim_player.is_playing() or anim_player.current_animation != "left_slash":
			## Xác định hướng dựa trên chuột
			#var mouse_pos = get_global_mouse_position()
			#var is_left = mouse_pos.x < Global.player.global_position.x
			#
			## Set hướng player và weapon
			#Global.player.anima.flip_h = is_left
			#Global.player.facing_direction = Vector2.LEFT if is_left else Vector2.RIGHT
			#scale.x = -1 if is_left else 1
			#
			## Bắt đầu tấn công
			#Global.player.is_attacking = true
			#anim_player.play("left_slash")
			#visible = true
			#AudioManager.play_sfx("slash")
#
#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "left_slash":
		#anim_player.play("left_return")
		#visible = false
		#Global.player.is_attacking = false
#
#func _on_area_2d_body_entered(body: Node2D) -> void:
	#if body.is_in_group("Enemy"):
		#print("danh trung")
		#AudioManager.play_sfx("hit")
		#body.get_damaged(damage)
		#body.knockback_force = (body.global_position - Global.player.global_position).normalized() * force
