extends State


@export var fall_state: State
@export var idle_state: State
@export var jump_state: State
@export var attack_state: State
@export var crouch_state: State
# -- Tunable movement parameters ------------------------------------------------
@export var max_speed: float = 200.0               # Units per second (top horizontal speed)
@export var acceleration: float = 800.0            # Units per second² when pressing a direction
@export var deceleration: float = 600.0            # Units per second² when no directional input
@export var idle_transition_vel: float = 50.0 
# ------------------------------------------------------------------------------


func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed("jump"):
		if parent.can_jump():
			if parent.can_ground_jump():
				print("Normal ground jump from move state!")
			else:
				print("Coyote jump from move state!")
			return jump_state
		else:
			# Can't jump right now, but buffer the input
			parent.buffer_jump()
	if Input.is_action_just_pressed('attack'):
		return attack_state
	if Input.is_action_just_pressed('crouch'):
		return crouch_state
	return null

func process_physics(delta: float) -> State:
	print("moving " + str(parent.velocity.x))
	# Apply gravity
	parent.velocity.y += gravity * delta

	# Horizontal movement with acceleration / deceleration
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = input_axis * max_speed

	if input_axis != 0.0:
		# Accelerate toward the desired speed
		parent.velocity.x = move_toward(parent.velocity.x, target_speed, acceleration * delta)
		parent.animations.flip_h = parent.velocity.x < 0
	else:
		# No input → slow the character down smoothly
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)

	parent.move_and_slide()

	# Check for buffered jump that can now be executed
	if parent.has_valid_jump_buffer() and parent.can_jump():
		print("Executing buffered jump from move state!")
		parent.consume_jump_buffer()
		return jump_state

	# State transitions ---------------------------------------------------------
	if input_axis == 0.0 and parent.is_on_floor() and abs(parent.velocity.x) < idle_transition_vel:
		return idle_state
	if !parent.is_on_floor():
		return fall_state

	return null
