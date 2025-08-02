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
	return null

func process_physics(delta: float) -> State:
	parent.velocity.y += gravity * delta
	parent.move_and_slide()
	
	# Check for buffered jump that can now be executed
	if parent.has_valid_jump_buffer() and parent.can_jump():
		print("Executing buffered jump from idle state!")
		parent.consume_jump_buffer()
		return jump_state
	
	if !parent.is_on_floor():
		return fall_state
	return null
