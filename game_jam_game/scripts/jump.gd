extends State

@export var fall_state: State
@export var land_state: State
@export var move_state: State
@export var idle_state: State
@export var air_attack_state: State
@export var dash_state: State


# ── Jump variants ───────────────────────────────────────────────
@export var short_hop_force: float			= 250.0		# initial impulse (increased for faster jumping)
@export var long_hop_force: float			= 400.0		# extra impulse if held (increased for faster jumping)
@export var long_hop_threshold: float		= 0.09		# Very short threshold for smooth upgrade
@export var short_gravity_scale: float		= 600.0		# reduced gravity for faster jumps
@export var long_gravity_scale: float		= 1200.0		# reduced gravity for faster jumps
@export var allow_long_jump_on_repeat: bool = false	# Whether repeated jumps can become long jumps

# ── Air camera panning (same as fall state) ────────────────────
@export var air_camera_offset_y: float = 40.0  # How much to move camera down when in air (less than fall state)
@export var air_camera_transition_speed: float = 4.0  # Speed of camera transition for air panning
@export var air_camera_pan_delay: float = 0.2  # Seconds to wait before camera starts panning down in air (longer for jumps)

# ── Shared air control ──────────────────────────────────────────
@export var inherit_ground_vel_mult: float	= 1.0
@export var air_accel: float				= 600.0
@export var air_friction: float				= 0.0
@export var max_air_speed: float			= 300.0
@export var sword_offset_y: float			= -20.0		# How much to move sword up during jump

# Head bonk enhanced air control
@export var head_bonk_air_control_boost: float = 1.5  # Extra air control after head bonk
var head_bonk_enhanced_control: bool = false
var head_bonk_control_duration: float = 0.5  # How long enhanced control lasts
var head_bonk_control_timer: float = 0.0
# ────────────────────────────────────────────────────────────────

var _hold_time := 0.0
var _is_long := false
var _was_fresh_press := true  # Track if this jump was from a fresh press or held input
var original_sword_position: Vector2
var jump_start_time: float = 0.0  # Track when jump started for head bonk timing

# Air camera panning state tracking
var original_camera_offset: Vector2
var target_camera_offset: Vector2
var air_timer: float = 0.0
var camera_tween: Tween  # For smooth camera transitions

func enter() -> void:
	super()
	print("JUMP STATE ENTERED")
	
	# Check if this should start as a long jump based on initial hold time
	var should_start_as_long = _hold_time >= long_hop_threshold and _was_fresh_press
	
	if should_start_as_long:
		# Start with long jump force
		parent.velocity.y = -long_hop_force
		_is_long = true
		print("Started as buffered long jump! Hold time: ", _hold_time)
	else:
		# Start with short hop, can upgrade to long jump if held
		parent.velocity.y = -short_hop_force
		_is_long = false
	
	parent.velocity.x *= inherit_ground_vel_mult			# carry runway speed
	jump_start_time = parent.total_time
	
	# Reset air timer for camera panning
	air_timer = 0.0
	
	# Store original camera offset and set target for air panning
	if parent.camera:
		original_camera_offset = parent.camera.offset
		target_camera_offset = original_camera_offset + Vector2(0, air_camera_offset_y)
		
		# Kill any existing camera tween
		if camera_tween:
			camera_tween.kill()
	
	# Mark that player jumped off ground (this will disable coyote time)
	parent.mark_jumped_off_ground()
	
	# Consume coyote time when jumping
	parent.coyote_timer = 0.0
	parent.coyote_available = false
	
	# Store original sword position and move it up slightly during jump
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

# Call this to mark whether this jump was from a fresh press or held input
func set_fresh_press(is_fresh: bool):
	_was_fresh_press = is_fresh

# Call this to set initial hold time for buffered long jumps
func set_initial_hold_time(hold_time: float):
	_hold_time = hold_time
	print("Jump started with initial hold time: ", hold_time)

# Reset hold time (call this for fresh jumps)
func reset_hold_time():
	_hold_time = 0.0
	print("Hold time reset for fresh jump")

func exit() -> void:
	# Smoothly reset camera offset when exiting jump state
	if parent.camera and camera_tween:
		camera_tween.kill()
		camera_tween = parent.create_tween()
		camera_tween.set_ease(Tween.EASE_OUT)
		camera_tween.set_trans(Tween.TRANS_QUART)
		camera_tween.tween_property(parent.camera, "offset", original_camera_offset, 0.3)
	elif parent.camera:
		parent.camera.offset = original_camera_offset
	
	# Reset sword position when exiting jump, but let player handle direction
	if parent.sword:
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction

func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed('attack'):
		return air_attack_state
	# Allow air dash during jump
	if Input.is_action_just_pressed('dash'):
		# Check if dash is available and air dash is enabled
		if dash_state and dash_state.is_dash_available() and dash_state.air_dash_enabled:
			return dash_state
		else:
			print("Air dash on cooldown or disabled!")
	return null

func process_physics(delta: float) -> State:
	# Update dash cooldown
	if dash_state:
		dash_state.update_cooldown(delta)
		
	# Track how long the jump key is held for long jump upgrade
	if Input.is_action_pressed("jump"):
		_hold_time += delta
		# Only upgrade to long jump if:
		# 1. Not already a long jump
		# 2. Held long enough
		# 3. Either this was a fresh press OR we allow long jumps on repeated input
		var can_upgrade_to_long = !_is_long and _hold_time >= long_hop_threshold
		var should_upgrade = can_upgrade_to_long and (_was_fresh_press or allow_long_jump_on_repeat)
		
		if should_upgrade:
			# Set full long jump velocity instead of adding boost
			parent.velocity.y = -long_hop_force
			_is_long = true
			print("Upgraded to long jump (fresh press: ", _was_fresh_press, ")")
	
	# Use appropriate gravity scale based on jump type
	var current_gravity_scale = short_gravity_scale
	if _is_long:
		current_gravity_scale = long_gravity_scale

	# Horizontal air control
	var axis := Input.get_axis("move_left", "move_right")
	var target := axis * max_air_speed
	
	# Enhanced air control if we recently head bonked
	var current_air_accel = air_accel
	if head_bonk_enhanced_control:
		head_bonk_control_timer -= delta
		current_air_accel *= head_bonk_air_control_boost
		
		if head_bonk_control_timer <= 0.0:
			head_bonk_enhanced_control = false
			print("Enhanced air control expired")

	if axis != 0:
		parent.velocity.x = move_toward(parent.velocity.x, target, current_air_accel * delta)
		parent.animations.flip_h = axis < 0
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, air_friction * delta)

	# Apply gravity based on hop type
	parent.velocity.y += gravity * current_gravity_scale * delta

	parent.move_and_slide()
	
	# Check for head bonk (ceiling collision while moving up)
	# Only check during the early part of the jump for authentic feel
	var time_since_jump_start = parent.total_time - jump_start_time
	
	if time_since_jump_start <= parent.head_bonk_grace_period and parent.velocity.y < 0:
		if parent.check_and_handle_head_bonk():
			# Head bonk occurred - enable enhanced air control and transition to fall state
			head_bonk_enhanced_control = true
			head_bonk_control_timer = head_bonk_control_duration
			print("Enhanced air control activated after head bonk!")
			return fall_state

	# State transitions
	if parent.velocity.y > 0:
		# Pass enhanced control to fall state if active
		if head_bonk_enhanced_control:
			fall_state.receive_enhanced_control(head_bonk_control_timer, head_bonk_air_control_boost)
		return fall_state
	if parent.is_on_floor():
		return land_state
	return null

func process_frame(delta: float) -> State:
	# Update air timer for camera panning
	air_timer += delta
	
	# Start smooth camera panning after the delay (longer delay for jumps than falls)
	if parent.camera and air_timer >= air_camera_pan_delay and not camera_tween:
		camera_tween = parent.create_tween()
		camera_tween.set_ease(Tween.EASE_OUT)
		camera_tween.set_trans(Tween.TRANS_QUART)
		camera_tween.tween_property(parent.camera, "offset", target_camera_offset, 0.4)  # Smooth 0.4 second transition
	
	return null
