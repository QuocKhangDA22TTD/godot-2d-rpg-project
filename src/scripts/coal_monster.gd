extends CharacterBody2D

var health = 10.0
var speed = 50.0
var damage = 1.0

var knockback_force: Vector2 = Vector2.ZERO
var knockback_timer = 0.0
var knockback_duration = 0.05

var attack_range = 20.0
var attack_cooldown = 1.0
var attack_timer = 0.0

var dash_speed = 200.0
var dash_duration = 0.2
var dash_timer = 0.0

@onready var anim = $AnimatedSprite2D
@onready var anima_player = $AnimatedSprite2D/AnimationPlayer

func _ready():
	anim.play("run")

func _physics_process(delta: float) -> void:
	if dash_timer > 0:
		dash_timer -= delta
		move_and_slide()
		return
	
	if knockback_timer > 0:
		handle_knockback(delta)
		knockback_force.move_toward(Vector2.ZERO, delta)
	else:
		if Global.player:
			var distance = global_position.distance_to(Global.player.global_position)
			
			if distance <= attack_range and attack_timer <= 0:
				dash_to_player()
				attack_timer = attack_cooldown
			else:
				chase_player()
				
			attack_timer -= delta
	move_and_slide()

func handle_knockback(delta: float):
	if knockback_timer > 0:
		velocity = knockback_force
		knockback_timer -= delta

func get_damaged(amount: float):
	anima_player.play("hit")
	knockback_timer = knockback_duration
	health -= amount
	
	if health <= 0.0:
		queue_free()

func chase_player():
	if Global.player:
		var dir = Vector2(Global.player.global_position - global_position)
		var distance = global_position.distance_to(Global.player.global_position)
		
		if distance >= attack_range:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2(randf_range(-2, 2), randf_range(-2, 2))

func dash_to_player():
	var dir = (Global.player.global_position - global_position).normalized()
	velocity = dir * dash_speed
	dash_timer = dash_duration

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.player.take_damaged(damage)
