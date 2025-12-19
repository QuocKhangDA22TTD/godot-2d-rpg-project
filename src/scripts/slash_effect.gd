extends Node2D

@onready var anim = $AnimationPlayer

func _ready() -> void:
	if anim is AnimatedSprite2D:
		# Kiểm tra xem animation có loop không
		var sprite_frames = anim.sprite_frames
		var is_looping = sprite_frames.get_animation_loop("slash")
		
		print("[SlashEffect] Animation 'slash' is looping: ", is_looping)
		
		if is_looping:
			# Nếu loop, tắt loop đi
			sprite_frames.set_animation_loop("slash", false)
			print("[SlashEffect] Disabled loop for 'slash' animation")
		
		# Kết nối signal
		anim.animation_finished.connect(_on_anim_finished)
		anim.play("slash")
		print("[SlashEffect] Animation started")
	elif anim is AnimationPlayer:
		anim.animation_finished.connect(_on_anim_finished)
		anim.play("slash")
		print("[SlashEffect] Animation started")

func _on_anim_finished() -> void:
	print("[SlashEffect] Animation finished, destroying effect")
	queue_free()
