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
	if Input.is_action_just_pressed('jump') and parent.is_on_floor():
		return jump_state
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
	
	if !parent.is_on_floor():
		return fall_state
	return null
