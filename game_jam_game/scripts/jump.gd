extends State

@export var fall_state: State
@export var land_state: State
@export var move_state: State
@export var idle_state: State
@export var air_attack_state: State


# ── Jump variants ───────────────────────────────────────────────
@export var short_hop_force: float			= 750.0		# initial impulse
@export var long_hop_force: float			= 950.0		# extra impulse if held
@export var long_hop_threshold: float		= 0.15		# sec key must be held
@export var short_gravity_scale: float		= 10.0
@export var long_gravity_scale: float		= 10.0
# ── Shared air control ──────────────────────────────────────────
@export var inherit_ground_vel_mult: float	= 1.0
@export var air_accel: float				= 600.0
@export var air_friction: float				= 200.0
@export var max_air_speed: float			= 220.0
@export var sword_offset_y: float			= -20.0		# How much to move sword up during jump

# Head bonk enhanced air control
@export var head_bonk_air_control_boost: float = 1.5  # Extra air control after head bonk
var head_bonk_enhanced_control: bool = false
var head_bonk_control_duration: float = 0.5  # How long enhanced control lasts
var head_bonk_control_timer: float = 0.0
# ────────────────────────────────────────────────────────────────

var _hold_time := 0.0
var _is_long := false
var original_sword_position: Vector2
var jump_start_time: float = 0.0  # Track when jump started for head bonk timing

func enter() -> void:
	super()
	print("JUMP STATE ENTERED")
	parent.velocity.y = -short_hop_force				# start with short hop
	parent.velocity.x *= inherit_ground_vel_mult			# carry runway speed
	_hold_time = 0.0
	_is_long = false
	jump_start_time = parent.total_time
	
	# Mark that player jumped off ground (this will disable coyote time)
	parent.mark_jumped_off_ground()
	
	# Consume coyote time when jumping
	parent.coyote_timer = 0.0
	parent.coyote_available = false
	
	# Store original sword position and move it up slightly during jump
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

func exit() -> void:
	# Reset sword position when exiting jump, but let player handle direction
	if parent.sword:
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction

func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed('attack'):
		return air_attack_state
	return null

func process_physics(delta: float) -> State:
	# Track how long the jump key is held
	if Input.is_action_pressed("jump"):
		_hold_time += delta
		if !_is_long and _hold_time >= long_hop_threshold:
			parent.velocity.y -= (long_hop_force - short_hop_force)	# top-up impulse
			_is_long = true

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
	var g_scale := short_gravity_scale
	if _is_long:
		g_scale = long_gravity_scale
	parent.velocity.y += gravity * g_scale * delta

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
