extends State

@export var idle_state: State
@export var move_state: State
@export var fall_state: State

# ---- Tunables --------------------------------------------------------
@export var crouch_fall_gravity_scale: float = 4.0  # Faster fall when crouching
@export var camera_offset_y: float = 20.0  # How much to move camera down
@export var camera_transition_speed: float = 8.0  # Speed of camera transition
# ----------------------------------------------------------------------

var original_camera_offset: Vector2
var target_camera_offset: Vector2

func enter() -> void:
	parent.animations.play("crouch")
	# Store original camera offset and set target
	if parent.camera:
		original_camera_offset = parent.camera.offset
		target_camera_offset = original_camera_offset + Vector2(0, camera_offset_y)

func exit() -> void:
	# Reset camera offset when exiting crouch
	if parent.camera:
		parent.camera.offset = original_camera_offset

func process_input(_event: InputEvent) -> State:
	# Exit crouch when key is released
	if Input.is_action_just_released('crouch'):
		if parent.is_on_floor():
			# Check if we should go to move or idle
			var input_axis: float = Input.get_axis("move_left", "move_right")
			if input_axis != 0.0:
				return move_state
			else:
				return idle_state
		else:
			return fall_state
	return null

func process_physics(delta: float) -> State:
	# Apply enhanced gravity for fast fall
	if parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		# Fast fall when in air
		parent.velocity.y += gravity * crouch_fall_gravity_scale * delta
	
	# Handle horizontal movement while crouching (reduced)
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var crouch_move_speed = 100.0  # Slower movement while crouching
	
	if input_axis != 0.0:
		parent.velocity.x = move_toward(parent.velocity.x, input_axis * crouch_move_speed, 400.0 * delta)
		parent.animations.flip_h = input_axis < 0
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, 600.0 * delta)
	
	parent.move_and_slide()
	
	# Transition to fall if not on floor
	if !parent.is_on_floor():
		return fall_state
	
	return null

func process_frame(delta: float) -> State:
	# Smoothly move camera to crouch position
	if parent.camera:
		parent.camera.offset = parent.camera.offset.move_toward(target_camera_offset, camera_transition_speed * delta * 60)
	return null
