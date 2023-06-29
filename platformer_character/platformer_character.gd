class_name PlatformerCharacter
extends CharacterBody2D

signal jumped

const unit_to_pixel = 100.0
const JUMP_VELOCITY = -400.0

@export_category("Movement")
@export_range(0, 100) var max_speed : float
@export_range(0, 100) var max_acceleration : float
@export_range(0, 100) var max_deceleration : float
@export_range(0, 100) var max_turn_speed : float
@export_range(0, 100) var max_air_acceleration : float
@export_range(0, 100) var max_air_deceleration : float
@export_range(0, 100) var max_air_turn_speed : float
@export_category("Jumping")
@export_range(0, 100) var jump_height : float
@export_range(0, 100) var time_to_jump_apex  : float
@export_range(0, 100) var downward_movement_multiplier  : float

# Calculations
var direction_x : float
var desired_velocity : Vector2
var max_speed_change : float
var acceleration : float
var deceleration : float
var turn_speed : float
var jump_speed : float
var gravity_scale : float
var gravity_multiplier : float

# States
var on_ground : bool
var desired_jump : bool

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


func _input(event : InputEvent):
	on_move(event)
	on_jump(event)
	

func on_move(event : InputEvent):
	if event.is_action("move_left") or event.is_action("move_right"):
		direction_x = Input.get_axis("move_left","move_right")

func on_jump(event: InputEvent):
	if event.is_action_pressed("jump"):
		desired_jump = true

func _process(delta: float) -> void:
	desired_velocity = Vector2(direction_x, 0) * max_speed * unit_to_pixel

	var new_gravity : Vector2 = Vector2(0, (-2 * jump_height * unit_to_pixel) / (time_to_jump_apex * time_to_jump_apex * unit_to_pixel))
	gravity_scale = (new_gravity.y / gravity) * gravity_multiplier
 
func _physics_process(delta: float) -> void:
	on_ground = is_on_floor()

	acceleration = (max_acceleration * unit_to_pixel if on_ground else max_air_acceleration * unit_to_pixel)
	deceleration = (max_deceleration * unit_to_pixel if on_ground else max_air_deceleration * unit_to_pixel)
	turn_speed = (max_turn_speed * unit_to_pixel if on_ground else max_air_turn_speed * unit_to_pixel)

	jump_process(delta)

	if direction_x:
		if not sign(direction_x) == sign(velocity.x):
			max_speed_change = turn_speed * delta
		else:
			max_speed_change = acceleration * delta 
	else:
		max_speed_change = deceleration * delta

	velocity.x = move_toward(velocity.x, desired_velocity.x, max_speed_change)

	move_and_slide()

func jump_process(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if desired_jump:
		do_a_jump()
		return
	
	if velocity.y == 0 :
		gravity_multiplier = 1
	if velocity.y > 0.01 :
		gravity_multiplier = downward_movement_multiplier * unit_to_pixel


func do_a_jump():
	if on_ground:

		jumped.emit()
		desired_jump = false
		jump_speed = sqrt(-2.0 * gravity * gravity_scale * jump_height)

		jump_speed = jump_speed * unit_to_pixel * 2

		if velocity.y < 0.0:
			jump_speed = max(jump_speed - velocity.y, 0.0)
		elif velocity.y > 0.0:
			jump_speed -= abs(velocity.y)

		velocity.y -= jump_speed

	desired_jump = false