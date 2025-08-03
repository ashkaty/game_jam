extends State


@export
var fall_state: State
@export
var jump_state: State
@export
var move_state: State
@export 
var attack_state: State
@export
var crouch_state: State
@export
var dash_state: State
@export var animation_name: String = "Idle"

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(_event: InputEvent) -> State:
	# Input processing moved to process_frame for polling system
	return null

func process_frame(delta: float) -> State:
	# Handle input processing every frame using polling system
	if parent.is_action_just_pressed_once('jump'):
		if parent.can_jump():
			if parent.can_ground_jump():
				print("Normal ground jump from idle state!")
			else:
				print("Coyote jump from idle state!")
			jump_state.set_fresh_press(true)  # Mark as fresh press
			# Use the time already held from player tracking instead of resetting
			var current_hold_time = parent.get_current_jump_hold_time()
			print("Jump from idle - current hold time: ", current_hold_time)
			jump_state.set_initial_hold_time(current_hold_time)
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	# Check for held jump input for repetitive jumping
	elif parent.is_action_pressed_polling('jump'):
		if parent.can_jump():
			print("Repetitive jump from idle state!")
			jump_state.set_fresh_press(false)  # Mark as held input
			# For repetitive jumps, use current hold time
			var current_hold_time = parent.get_current_jump_hold_time()
			jump_state.set_initial_hold_time(current_hold_time)
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	if parent.is_action_pressed_polling('move_left') or parent.is_action_pressed_polling('move_right'):
		return move_state
	if parent.is_action_just_pressed_once('attack'):
		return attack_state
	if parent.is_action_just_pressed_once('crouch'):
		return crouch_state
	if parent.is_action_just_pressed_once('dash'):
		# Check if dash is available (cooldown check)
		if dash_state and dash_state.is_dash_available():
			return dash_state
		else:
			print("Dash on cooldown! Buffering dash input...")
			parent.buffer_dash()
	
	# Check for buffered inputs that can now be executed
	if parent.has_valid_dash_buffer() and dash_state and dash_state.is_dash_available():
		print("Executing buffered dash!")
		parent.consume_dash_buffer()
		return dash_state
	
	return null

func process_physics(delta: float) -> State:
	# Update dash cooldown
	if dash_state:
		dash_state.update_cooldown(delta)
		
	parent.velocity.y += gravity * delta
	parent.move_and_slide()
	
	# Check for buffered jump that can now be executed
	if parent.has_valid_jump_buffer() and parent.can_jump():
		print("Executing buffered jump from idle state!")
		var buffered_hold_time = parent.consume_jump_buffer()
		
		# Set up the jump state with the buffered hold time
		jump_state.set_fresh_press(true)  # Buffered jumps count as fresh
		jump_state.set_initial_hold_time(buffered_hold_time)
		
		return jump_state
	
	# Check for buffered dash that can now be executed
	if parent.has_valid_dash_buffer() and dash_state and dash_state.is_dash_available():
		print("Executing buffered dash from idle state!")
		parent.consume_dash_buffer()
		return dash_state
	
	if !parent.is_on_floor():
		return fall_state
	return null
