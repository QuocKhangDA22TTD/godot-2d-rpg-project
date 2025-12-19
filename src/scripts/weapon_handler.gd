extends Node

class_name WeaponHandler

@export var weapon_data: WeaponData

var is_attacking = false

func attack(player: Node2D, facing: Vector2):
	if is_attacking:
		return
	
	is_attacking = true
	
	player.weapon_pivot.rotation = facing.angle()
	
	if player.facing_direction == Vector2.RIGHT:
		player.weapon_anim.play("right_slash")
	if player.facing_direction == Vector2.LEFT:
		player.weapon_anim.play("left_slash")
	
	_spawn_hitbox(player, facing)
	
	await get_tree().create_timer(
		weapon_data.windup_time
		+ weapon_data.active_time
		+ weapon_data.recovery_time
	).timeout

	is_attacking = false

func _spawn_hitbox(player, facing):
	await get_tree().create_timer(weapon_data.windup_time).timeout

	var hitbox = weapon_data.hitbox_scene.instantiate()
	hitbox.global_position = player.global_position + facing * 16
	hitbox.direction = facing
	hitbox.damage = weapon_data.damage
	hitbox.knockback = weapon_data.knockback
	
	var slash_fx = weapon_data.slash_effect_scene.instantiate()
	slash_fx.global_position = hitbox.global_position + facing * 12
	slash_fx.rotation = facing.angle()
	
	print("[WeaponHandler] Spawning slash effect at: ", slash_fx.global_position)

	player.get_parent().add_child(hitbox)
	player.get_parent().add_child(slash_fx)
	
	print("[WeaponHandler] Slash effect added to scene tree")
	
	AudioManager.play_sfx("slash")

	await get_tree().create_timer(weapon_data.active_time).timeout
	hitbox.queue_free()
