class_name PlatformerCharacter
extends CharacterBody2D

signal jumped

const movement_multiplier = 32.0

@export_category("Movement")
@export_range(0, 20) var max_speed : float
@export_range(0, 100) var max_acceleration : float
@export_range(0, 100) var max_deceleration : float
@export_range(0, 100) var max_turn_speed : float
@export_range(0, 100) var max_air_acceleration : float
@export_range(0, 100) var max_air_deceleration : float
@export_range(0, 100) var max_air_turn_speed : float
@export var use_acceleration : bool
@export_category("Jumping")
@export_range(2, 5.5) var jump_height : float
@export_range(0.2, 1.25) var time_to_jump_apex  : float
@export_range(0, 5) var upward_movement_multiplier : float
@export_range(1, 10) var downward_movement_multiplier  : float
@export_range(0, 1) var max_air_jumps : int
@export_category("Jumping Advanced")
@export var variable_jump_height : bool
@export_range(1, 10) var jump_cut_off : float
@export var in_air_speed_limit : float
@export_range(0, 0.3) var coyote_time : float
@export_range(0, 0.3) var jump_buffer : float

# Calculations
var direction_x : float
var desired_velocity : Vector2
var max_speed_change : float
var acceleration : float
var deceleration : float
var turn_speed : float
var jump_speed : float
var default_gravity_scale : float
var gravity_scale : float
var gravity_multiplier : float

# States
# Movement
var pressing_movement_key : bool
# Jumping
var can_jump_again : bool
var desired_jump : bool
var jump_buffer_counter : float
var coyote_time_counter : float
var pressing_jump : bool
var currently_jumping : bool

var rng = RandomNumberGenerator.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _enter_tree() -> void:
	default_gravity_scale = 1


func _input(event : InputEvent) -> void:
	on_move(event)
	on_jump(event)
	

func on_move(event : InputEvent) -> void:
	# Check here if character should be able to move or not
	# For example, maybe character shouldn't be able to move when they get hurt and tp to last check point and when they die and game is reset
	# or we want to stop it's moving during story bit
	if event.is_action("move_left") or event.is_action("move_right"):
		direction_x = Input.get_axis("move_left","move_right")

func on_jump(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		desired_jump = true
		pressing_jump = true
	if event.is_action_released("jump"):
		pressing_jump = false

func _process(delta: float) -> void:
	# In here reset direction_x to zero if we have the ability to stop character movement

	if direction_x != 0:
		pressing_movement_key = true
	else:
		pressing_movement_key = false

	desired_velocity = Vector2(direction_x, 0) * max_speed * movement_multiplier

	if jump_buffer > 0:
		if desired_jump:
			jump_buffer_counter += delta
			
			if jump_buffer_counter > jump_buffer:
				desired_jump = false
				jump_buffer_counter = 0

	if !currently_jumping && !is_on_floor():
		coyote_time_counter += delta
	else:
		coyote_time_counter = 0

 
func _physics_process(delta: float) -> void:

	if use_acceleration:
		run_with_acceleration(delta)
	else:
		if is_on_floor():
			run_without_acceleration(delta)
		else:
			run_with_acceleration(delta)

	jump_process(delta)

	move_and_slide()

# MOVEMENT FUNCS

func run_with_acceleration(delta: float) -> void:

	acceleration = (max_acceleration * movement_multiplier if is_on_floor() else max_air_acceleration * movement_multiplier)
	deceleration = (max_deceleration * movement_multiplier if is_on_floor() else max_air_deceleration * movement_multiplier)
	turn_speed = (max_turn_speed * movement_multiplier if is_on_floor() else max_air_turn_speed * movement_multiplier)

	if pressing_movement_key:
		if not sign(direction_x) == sign(velocity.x):
			max_speed_change = turn_speed * movement_multiplier * delta
		else:
			max_speed_change = acceleration * movement_multiplier * delta 
	else:
		max_speed_change = deceleration * movement_multiplier * delta

	velocity.x = move_toward(velocity.x, desired_velocity.x, max_speed_change)

func run_without_acceleration(delta: float):
	velocity.x = desired_velocity.x

# JUMP FUNCS

func set_gravity() -> void:
	var new_gravity : Vector2 = Vector2(0, (-2 * jump_height) / (time_to_jump_apex * time_to_jump_apex))
	print(gravity_multiplier)
	gravity_scale = (new_gravity.y / gravity) * gravity_multiplier * movement_multiplier

func jump_process(delta: float) -> void:

	calculate_gravity(delta)	

	set_gravity()

	#calculate_gravity(delta)
	# Handle Jump.
	if desired_jump:
		do_a_jump()
		return
	



func calculate_gravity(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta * (-gravity_scale)

	if velocity.y < -0.01:
		if is_on_floor():
			gravity_multiplier = default_gravity_scale
		else:
			if variable_jump_height:
				if pressing_jump and currently_jumping:
					gravity_multiplier = upward_movement_multiplier
				else:
					gravity_multiplier = jump_cut_off
			else:
				gravity_multiplier = upward_movement_multiplier
	elif velocity.y > 0.01:
		if is_on_floor():
			gravity_multiplier = default_gravity_scale
		elif coyote_time_counter > 0:
			gravity_multiplier = default_gravity_scale
		else:
			gravity_multiplier = downward_movement_multiplier
	else:
		if is_on_floor():
			currently_jumping = false
		gravity_multiplier = default_gravity_scale

	velocity.y = clamp(velocity.y, -in_air_speed_limit, 1000)

func do_a_jump() -> void:
	if is_on_floor() or (coyote_time_counter > 0.03 and coyote_time_counter < coyote_time) or can_jump_again:
		jumped.emit()
		desired_jump = false
		jump_buffer_counter = 0
		coyote_time_counter = 0

		can_jump_again = max_air_jumps == 1 and can_jump_again == false

		jump_speed = sqrt(-2.0 * gravity * gravity_scale * jump_height * movement_multiplier)

		if velocity.y < 0.0:
			jump_speed = max(jump_speed - velocity.y, 0.0)
		elif velocity.y > 0.0:
			jump_speed -= abs(velocity.y)


		velocity.y -= jump_speed
		currently_jumping = true

	if jump_buffer == 0:
		desired_jump = false

func bounce_up(bounce_amount : float) -> void:
	pass