class_name PlatformerCharacter
extends CharacterBody2D

const unit_to_pixel = 100.0
const JUMP_VELOCITY = -400.0

@export_range(0, 100) var max_speed : float
@export_range(0, 100) var max_acceleration : float
@export_range(0, 100) var max_deceleration : float
@export_range(0, 100) var max_turn_speed : float
@export_range(0, 100) var max_air_acceleration : float
@export_range(0, 100) var max_air_deceleration : float
@export_range(0, 100) var max_air_turn_speed : float


# Calculations
var direction_x : float
var desired_velocity : Vector2
var max_speed_change : float
var acceleration : float
var deceleration : float
var turn_speed : float

# States
var on_ground : bool

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


func _input(event):
	direction_x = Input.get_axis("move_left","move_right")

func _process(delta: float) -> void:
	desired_velocity = Vector2(direction_x, 0) * max_speed * unit_to_pixel

func _physics_process(delta: float) -> void:
	on_ground = is_on_floor()

	acceleration = (max_acceleration * unit_to_pixel if on_ground else max_air_acceleration * unit_to_pixel)
	deceleration = (max_deceleration * unit_to_pixel if on_ground else max_air_deceleration * unit_to_pixel)
	turn_speed = (max_turn_speed * unit_to_pixel if on_ground else max_air_turn_speed * unit_to_pixel)

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	if direction_x:
		if not sign(direction_x) == sign(velocity.x):
			max_speed_change = turn_speed * delta
		else:
			max_speed_change = acceleration * delta 
	else:
		max_speed_change = deceleration * delta

	velocity.x = move_toward(velocity.x, desired_velocity.x, max_speed_change)

	move_and_slide()
