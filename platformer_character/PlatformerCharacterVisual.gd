extends AnimatedSprite2D

@export var character_controller : PlatformerCharacter


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if character_controller.velocity.x == 0:
		play("idle")
	else:
		play("run")

	if not character_controller.velocity.x == 0:
		if character_controller.velocity.x > 0:
			flip_h = false
		else:
			flip_h = true
