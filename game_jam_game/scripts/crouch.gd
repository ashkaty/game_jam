extends State

@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var ground_attack_state: State
@export var dash_state: State
# ---- Tunables --------------------------------------------------------
@export var crouch_fall_gravity_scale: float = 4.0  # Faster fall when crouching
@export var camera_offset_y: float = 80.0  # How much to move camera down (increased for better view while falling)
@export var camera_transition_speed: float = 4.0  # Slower, smoother camera transition
@export var camera_pan_delay: float = 0.05  # Shorter delay for more responsive feel
@export var sword_offset_y: float = 30.0  # How much to move sword down when crouching

# ----------------------------------------------------------------------

var original_camera_offset: Vector2
var target_camera_offset: Vector2
var original_sword_position: Vector2
var crouch_timer: float = 0.0
var camera_tween: Tween  # For smooth camera transitions

func enter() -> void:
	parent.animations.play("crouch")
	crouch_timer = 0.0  # Reset timer when entering crouch
	
	# Store original camera offset and set target
	if parent.camera:
		original_camera_offset = parent.camera.offset
		target_camera_offset = original_camera_offset + Vector2(0, camera_offset_y)
		
		# Kill any existing camera tween
		if camera_tween:
			camera_tween.kill()
	
	# Store original sword position and move it down slightly
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

func exit() -> void:
	# Smoothly reset camera offset when exiting crouch
	if parent.camera and camera_tween:
		camera_tween.kill()
		camera_tween = parent.create_tween()
		camera_tween.set_ease(Tween.EASE_OUT)
		camera_tween.set_trans(Tween.TRANS_QUART)
		camera_tween.tween_property(parent.camera, "offset", original_camera_offset, 0.3)
	elif parent.camera:
		parent.camera.offset = original_camera_offset

	# Reset sword position when exiting crouch
	if parent.sword:
		# Instead of restoring stored position, reset to base position and let player update logic handle direction
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction


func process_input(_event: InputEvent) -> State:
	# Handle jump input - buffer it since we can't jump while crouching
	if parent.is_action_just_pressed_once('jump'):
		parent.buffer_jump()
		
	# Handle dash input - can dash from crouch
	if parent.is_action_just_pressed_once('dash'):
		# Check if dash is available
		if dash_state and dash_state.is_dash_available():
			return dash_state
		else:
			print("Dash on cooldown!")
		
	# Exit crouch when key is released
	if parent.is_action_just_pressed_once("attack"):
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
	# Update dash cooldown
	if dash_state:
		dash_state.update_cooldown(delta)
		
	# Apply enhanced gravity for fast fall
	if parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		# Fast fall when in air
		parent.velocity.y += gravity * crouch_fall_gravity_scale * delta
	
	# Handle horizontal movement while crouching (reduced)
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var crouch_move_speed = 100.0  # Slower movement while crouching
	var crouch_acceleration = 400.0
	var crouch_deceleration = 800.0  # Increased for more responsive crouching
	
	if input_axis != 0.0:
		# Check if we're changing direction (input and current velocity have opposite signs)
		var is_changing_direction = (input_axis > 0 and parent.velocity.x < 0) or (input_axis < 0 and parent.velocity.x > 0)
		
		# Apply stronger braking force when changing directions while crouching
		var effective_acceleration = crouch_acceleration
		if is_changing_direction:
			effective_acceleration = crouch_acceleration * 1.8  # Strong braking for precise crouch movement
		
		parent.velocity.x = move_toward(parent.velocity.x, input_axis * crouch_move_speed, effective_acceleration * delta)
		parent.animations.flip_h = input_axis < 0
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, crouch_deceleration * delta)
	
	parent.move_and_slide()
	
	# Check for buffered jump that can now be executed (but only if we're on floor and can jump)
	if parent.has_valid_jump_buffer() and parent.is_on_floor() and parent.can_jump():
		# print("Executing buffered jump from crouch state!")
		parent.consume_jump_buffer()
		# Exit crouch and let the state machine handle the jump in the next state
		# Reuse the input_axis variable already declared above
		if input_axis != 0.0:
			return move_state
		else:
			return idle_state
	
	# Transition to fall if not on floor
	if !parent.is_on_floor():
		return fall_state
	
	return null

func process_frame(delta: float) -> State:
	# Update crouch timer
	crouch_timer += delta
	
	# Start smooth camera panning after the delay
	if parent.camera and crouch_timer >= camera_pan_delay and not camera_tween:
		camera_tween = parent.create_tween()
		camera_tween.set_ease(Tween.EASE_OUT)
		camera_tween.set_trans(Tween.TRANS_QUART)
		camera_tween.tween_property(parent.camera, "offset", target_camera_offset, 0.6)  # Smooth 0.6 second transition
	return null
