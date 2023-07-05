extends AnimatedSprite2D

@export var character_controller : PlatformerCharacter

var jumped : bool
var wall_grabbed : bool
var landed : bool

func _ready() -> void:
	character_controller.jumped.connect(jump)
	character_controller.wall_grabbed.connect(wall_grab)
	animation_finished.connect(animation_finish)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	movement()

	if jumped and not wall_grabbed:
		if character_controller.velocity.y == 0:
			jumped = false
			landed = true
			play("jump_land")

	if character_controller.velocity.y > 0 and not wall_grabbed:
		play("jump_down")
	
	if 	wall_grabbed:
		if character_controller.velocity.y != 0 and animation != "wall_climb":
			play("wall_climb")
		elif character_controller.velocity.y == 0 and animation != "wall_grab":
			play("wall_grab")
	
	if not character_controller.is_grabbing:
		wall_grabbed = false
	if not character_controller.velocity.x == 0:
		if character_controller.velocity.x > 0:
			flip_h = false
		else:
			flip_h = true

func animation_finish() -> void:
	if animation == "jump_land":
		landed = false

func movement() -> void:
	if character_controller.velocity.y != 0:
		return
	if jumped:
		return
	if wall_grabbed:
		return
	if character_controller.velocity.x == 0:
		if landed:
			return
		play("idle")
	else:
		if landed:
			landed = false
		play("run")

func jump() -> void:
	play("jump_up")
	jumped = true

func wall_grab() -> void:
	play("wall_grab")
	wall_grabbed = true
