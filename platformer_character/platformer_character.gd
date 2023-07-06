class_name PlatformerCharacter
extends CharacterBody2D


## A simple 2d platformer controller based on GMTK platformer controller
##
## This script is a rewritten GMTK character controller for 2d platformers, inside godot.
## There will be also added extra features that GMTK character controller doesn't posses
##
## @tutorial(GMTK Platformer Toolkit):            https://gmtk.itch.io/platformer-toolkit

signal jumped
signal wall_grabbed

const movement_multiplier = 32.0

@export_category("Movement")

## Maximum movement speed
@export_range(0, 20) var max_speed : float
## How fast to reach max speed
@export_range(0, 100) var max_acceleration : float
## How fast to stop after letting go
@export_range(0, 100) var max_deceleration : float
## How fast to stop when changing direction
@export_range(0, 100) var max_turn_speed : float
## How fast to reach max speed when in mid-air
@export_range(0, 100) var max_air_acceleration : float
## How fast to stop in mid-air when no direction is used
@export_range(0, 100) var max_air_deceleration : float
## How fast to stop when changing direction when in mid-air
@export_range(0, 100) var max_air_turn_speed : float
## When false, the charcter will skip acceleration and deceleration and instantly move and stop
@export var use_acceleration : bool
@export_category("Climbing")
## Do we want enable grabing the wall/climbing mechanics?
@export var enable_climbing : bool
## How long should grab time last?
@export_range(0, 2) var grab_time : float
@export_category("Jumping")
## Maximum jump height
@export_range(2, 5.5) var jump_height : float
## How long it takes to reach that height before coming back down
@export_range(0.2, 1.25) var time_to_jump_apex  : float
## Gravity multiplier to apply when going up
@export_range(0, 5) var upward_movement_multiplier : float
## Gravity multiplier to apply when coming down
@export_range(1, 10) var downward_movement_multiplier  : float
## How many times can you jump in the air
@export_range(0, 1) var max_air_jumps : int
@export_category("Jumping Advanced")
## Should the character drop when you let go of jump?
@export var variable_jump_height : bool
## Gravity multiplier when you let go of jump
@export_range(1, 10) var jump_cut_off : float
## The fastest speed the character can be when in air
@export var in_air_speed_limit : float
## How long should coyote time last?
@export_range(0, 0.3) var coyote_time : float
## How far from ground should we cache your jump?
@export_range(0, 0.3) var jump_buffer : float
@export_category("Jumping Sounds")
@export var jump_sound : AudioStreamPlayer


# Calculations
var direction_x : float
var direction_y : float
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
var walk_mode_toggled : bool
# Jumping
var can_jump_again : bool
var desired_jump : bool
var jump_buffer_counter : float
var coyote_time_counter : float
var pressing_jump : bool
var currently_jumping : bool
var on_wall : bool
var is_grabbing : bool
var desired_grab : bool
var remaining_grab_time : float

var rng = RandomNumberGenerator.new()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _enter_tree() -> void:
	default_gravity_scale = 1


func _input(event : InputEvent) -> void:
	on_move(event)
	on_jump(event)
	if enable_climbing:
		on_grab(event)
		on_climb(event)

func on_move(event : InputEvent) -> void:
	# Check here if character should be able to move or not
	# For example, maybe character shouldn't be able to move when they get hurt and tp to last check point and when they die and game is reset
	# or we want to stop it's moving during story bit
	if event.is_action_pressed("toggle_walk"):
		walk_mode_toggled = not walk_mode_toggled


	var gamepad_input_dir = Input.get_axis("move_left_gamepad","move_right_gamepad")
	var input_dir = Input.get_axis("move_left","move_right")

	if gamepad_input_dir!=0:
		direction_x = sign(gamepad_input_dir)
	else:
		direction_x = input_dir

func on_climb(event: InputEvent) -> void:
	# Check here if character should be able to move or not
	# For example, maybe character shouldn't be able to move when they get hurt and tp to last check point and when they die and game is reset
	# or we want to stop it's moving during story bit

	var gamepad_input_dir = Input.get_axis("move_up_gamepad","move_down_gamepad")
	var input_dir = Input.get_axis("move_up","move_down")

	if gamepad_input_dir!=0:
		direction_y = sign(gamepad_input_dir)
	else:
		direction_y = input_dir

func on_jump(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		desired_jump = true
		pressing_jump = true
	if event.is_action_released("jump"):
		pressing_jump = false
		
func on_grab(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		is_grabbing = true
		desired_grab = true
		
	if event.is_action_released("grab"):
		is_grabbing = false
		
func _process(delta: float) -> void:
	# In here reset direction_x to zero if we have the ability to stop character movement
	
	if is_on_wall_only() and is_grabbing:
		if desired_grab:
			desired_grab = false
			wall_grabbed.emit()
		remaining_grab_time -= delta
		if remaining_grab_time <= 0:
			remaining_grab_time = grab_time
			is_grabbing = false
	elif is_on_floor():
		remaining_grab_time = grab_time

	if direction_x != 0:
		pressing_movement_key = true
	else:
		pressing_movement_key = false

	desired_velocity = Vector2(direction_x, direction_y) * max_speed * movement_multiplier

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
	if not is_on_wall_only() or not is_grabbing:
		if use_acceleration:
			run_with_acceleration(delta)
		else:
			if is_on_floor():
				run_without_acceleration(delta)
			else:
				run_with_acceleration(delta)
	
	jump_process(delta)
	
	if is_on_wall_only() and is_grabbing:
		climb_without_acceleration(delta)
	
	if walk_mode_toggled and is_on_floor():
		velocity.x = velocity.x / 3
	
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
	
func climb_without_acceleration(delta: float):
	velocity.y = desired_velocity.y

# JUMP FUNCS

func set_gravity() -> void:
	var new_gravity : Vector2 = Vector2(0, (-2 * jump_height) / (time_to_jump_apex * time_to_jump_apex))
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
	if is_on_wall_only() and is_grabbing:
		if velocity.y != 0:
			velocity.y = 0
		currently_jumping = false
		return
	
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
	if is_on_wall_only() and is_grabbing:
		do_a_jump_calc()
		is_grabbing = false
		
		#velocity.x = move_toward(velocity.x, -desired_velocity.x, max_speed_change)
		return
	
	if is_on_floor() or (coyote_time_counter > 0.03 and coyote_time_counter < coyote_time) or can_jump_again:
		do_a_jump_calc()
		jump_sound.play()
		
func do_a_jump_calc() -> void:
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
