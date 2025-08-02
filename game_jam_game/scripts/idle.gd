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

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed('jump'):
		if parent.can_jump():
			if parent.can_ground_jump():
				print("Normal ground jump from idle state!")
			else:
				print("Coyote jump from idle state!")
			jump_state.set_fresh_press(true)  # Mark as fresh press
			jump_state.reset_hold_time()  # Reset hold time for fresh jump
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	# Check for held jump input for repetitive jumping
	elif Input.is_action_pressed('jump'):
		if parent.can_jump():
			print("Repetitive jump from idle state!")
			jump_state.set_fresh_press(false)  # Mark as held input
			jump_state.reset_hold_time()  # Reset hold time even for held jumps
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	if Input.is_action_just_pressed('move_left') or Input.is_action_just_pressed('move_right'):
		return move_state
	if Input.is_action_just_pressed('attack'):
		return attack_state
	if Input.is_action_just_pressed('crouch'):
		return crouch_state
	if Input.is_action_just_pressed('dash'):
		# Check if dash is available (cooldown check)
		if dash_state and dash_state.is_dash_available():
			return dash_state
		else:
			print("Dash on cooldown!")
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
	
	if !parent.is_on_floor():
		return fall_state
	return null
