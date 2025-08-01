extends State

@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var ground_attack_state: State
# ---- Tunables --------------------------------------------------------
@export var crouch_fall_gravity_scale: float = 4.0  # Faster fall when crouching
@export var camera_offset_y: float = 40.0  # How much to move camera down
@export var camera_transition_speed: float = 8.0  # Speed of camera transition
@export var camera_pan_delay: float = 0.1  # Seconds to wait before camera starts panning down
@export var sword_offset_y: float = 30.0  # How much to move sword down when crouching

# ----------------------------------------------------------------------

var original_camera_offset: Vector2
var target_camera_offset: Vector2
var original_sword_position: Vector2
var crouch_timer: float = 0.0

func enter() -> void:
	parent.animations.play("crouch")
	crouch_timer = 0.0  # Reset timer when entering crouch
	# Store original camera offset and set target
	if parent.camera:
		original_camera_offset = parent.camera.offset
		target_camera_offset = original_camera_offset + Vector2(0, camera_offset_y)
	# Store original sword position and move it down slightly
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

func exit() -> void:
	# Reset camera offset when exiting crouch
	if parent.camera:
		parent.camera.offset = original_camera_offset

	# Reset sword position when exiting crouch
	if parent.sword:
		# Instead of restoring stored position, reset to base position and let player update logic handle direction
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction


func process_input(_event: InputEvent) -> State:
	# Exit crouch when key is released
	if Input.is_action_pressed("attack"):
		return ground_attack_state
	if Input.is_action_just_released('crouch'):
		if parent.is_on_floor():
			# Check if we should go to move or idle
			var input_axis: float = Input.get_axis("move_left", "move_right")
			if input_axis != 0.0:
				return move_state
			else:
				return idle_state
		else:
			# If we release crouch while in air, go to fall state
			# The fall state will handle normal falling mechanics
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
	# Update crouch timer
	crouch_timer += delta
	
	# Only start panning camera down after the delay
	if parent.camera and crouch_timer >= camera_pan_delay:
		parent.camera.offset = parent.camera.offset.move_toward(target_camera_offset, camera_transition_speed * delta * 60)
	return null
