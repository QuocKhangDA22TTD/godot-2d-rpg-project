extends Area2D

var damage = 2.0
var knockback = 160.0
var direction = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("get_damaged"):
		body.get_damaged(damage)
		body.knockback_force = (body.global_position - Global.player.global_position).normalized() * knockback
