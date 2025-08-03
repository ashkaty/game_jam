extends State


@export var fall_state: State
@export var idle_state: State
@export var jump_state: State
@export var attack_state: State
@export var crouch_state: State
@export var dash_state: State
# -- Tunable movement parameters ------------------------------------------------
@export var max_speed: float = 150.0               # Units per second (top horizontal speed)
@export var acceleration: float = 600.0            # Units per second² when pressing a direction
@export var deceleration: float = 800.0            # Units per second² when no directional input (increased for quicker stops)
@export var direction_change_multiplier: float = 2.0  # Extra braking force when changing directions
@export var idle_transition_vel: float = 50.0
# @export var animation_name: String = "run"
# ------------------------------------------------------------------------------


func process_input(_event: InputEvent) -> State:
	# Input processing moved to process_frame for polling system
	return null

func process_frame(delta: float) -> State:
	# Handle input processing every frame using polling system
	if parent.is_action_just_pressed_once("jump"):
		if parent.can_jump():
			#if parent.can_ground_jump():
				# print("Normal ground jump from move state!")
			#else:
				# print("Coyote jump from move state!")
			jump_state.set_fresh_press(true)  # Mark as fresh press
			# Use the time already held from player tracking instead of resetting
			var current_hold_time = parent.get_current_jump_hold_time()
			jump_state.set_initial_hold_time(current_hold_time)
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	# Check for held jump input for repetitive jumping
	elif parent.is_action_pressed_polling("jump"):
		if parent.can_jump():
			# print("Repetitive jump from move state!")
			jump_state.set_fresh_press(false)  # Mark as held input
			# For repetitive jumps, use current hold time
			var current_hold_time = parent.get_current_jump_hold_time()
			jump_state.set_initial_hold_time(current_hold_time)
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	if parent.is_action_just_pressed_once('attack'):
		return attack_state
	if parent.is_action_just_pressed_once('crouch'):
		return crouch_state
	if parent.is_action_just_pressed_once('dash'):
		# Check if dash is available (cooldown check)
		if dash_state and dash_state.is_dash_available():
			return dash_state
		else:
			# print("Dash on cooldown! Buffering dash input...")
			parent.buffer_dash()
	
	# Check for buffered inputs that can now be executed
	if parent.has_valid_dash_buffer() and dash_state and dash_state.is_dash_available():
		# print("Executing buffered dash!")
		parent.consume_dash_buffer()
		return dash_state
	
	return null

func process_physics(delta: float) -> State:
	# print("moving " + str(parent.velocity.x))
	
	# Update dash cooldown
	if dash_state:
		dash_state.update_cooldown(delta)
	
	# Apply gravity
	parent.velocity.y += gravity * delta

	# Horizontal movement with acceleration / deceleration
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = input_axis * max_speed

	if input_axis != 0.0:
		# Check if we're changing direction (input and current velocity have opposite signs)
		var is_changing_direction = (input_axis > 0 and parent.velocity.x < 0) or (input_axis < 0 and parent.velocity.x > 0)
		
		# Apply stronger braking force when changing directions
		var effective_acceleration = acceleration
		if is_changing_direction:
			effective_acceleration = acceleration 
			parent.velocity.x = move_toward(parent.velocity.x, target_speed, effective_acceleration * delta)
		else:
 # No input → slow the character down smoothly with increased deceleration
			parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)
			parent.move_and_slide()

	# Check for buffered jump that can now be executed
			parent.set_facing_left(parent.velocity.x < 0)
			parent.move_and_slide()
	
	if parent.has_valid_jump_buffer() and parent.can_jump():
		# print("Executing buffered jump from move state!")
		var buffered_hold_time = parent.consume_jump_buffer()
		
		# Set up the jump state with the buffered hold time
		jump_state.set_fresh_press(true)  # Buffered jumps count as fresh
		jump_state.set_initial_hold_time(buffered_hold_time)
		
		return jump_state
	
	# Check for buffered dash that can now be executed
	if parent.has_valid_dash_buffer() and dash_state and dash_state.is_dash_available():
		# print("Executing buffered dash from move state!")
		parent.consume_dash_buffer()
		return dash_state

	# State transitions ---------------------------------------------------------
	if input_axis == 0.0 and parent.is_on_floor() and abs(parent.velocity.x) < idle_transition_vel:
		return idle_state
	if !parent.is_on_floor():
		return fall_state

	return null
