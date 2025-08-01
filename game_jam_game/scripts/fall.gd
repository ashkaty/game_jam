extends State

@export var land_state: State
@export var move_state: State
@export var idle_state: State
@export var jump_state: State
@export var air_attack_state: State
@export var crouch_state: State

# ---- Tunables --------------------------------------------------------
@export var fall_gravity_scale: float = 2.6
@export var fast_fall_gravity_scale: float = 4.5  # Much faster fall when crouching in air
@export var terminal_velocity: float  = 1200.0
@export var fast_fall_terminal_velocity: float = 1800.0  # Higher terminal velocity for fast fall
@export var air_accel: float          = 600.0
@export var air_friction: float       = 300.0
@export var max_air_speed: float      = 220.0
@export var fast_fall_air_speed: float = 150.0  # Reduced air control during fast fall
@export var sword_offset_y: float     = -15.0  # How much to move sword up during fall
# ----------------------------------------------------------------------

var original_sword_position: Vector2

func enter() -> void:
	super()
	print("Entering fall state")
	# Store original sword position and move it up slightly during fall
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

func exit() -> void:
	# Reset sword position when exiting fall, but let player handle direction
	if parent.sword:
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction

func process_frame(delta: float) -> State:
	# Update animation based on whether player is fast falling
	if Input.is_action_pressed("crouch"):
		parent.animations.play("crouch")
	elif Input.is_action_pressed("shift"):
		# You can add a specific fast fall animation here if one exists
		# For now, we'll let the default animation play or use crouch
		parent.animations.play("crouch")  # Using crouch animation for shift fast fall too
	else:
		# You can add a specific fall animation here if one exists
		# For now, we'll let the default animation play
		pass
	return null

func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed("jump"):
		if parent.can_coyote_jump():
			print("Coyote jump from fall state!")
			return jump_state
			
	if Input.is_action_just_pressed('attack'):
		return air_attack_state
		
	# Don't transition to crouch state if already holding crouch
	# This prevents unnecessary state switching between fall and crouch
	if Input.is_action_just_pressed('crouch'):
		return crouch_state
	return null

func process_physics(delta: float) -> State:
	# Check if player is holding crouch or shift for fast fall
	var is_fast_falling = Input.is_action_pressed("crouch") or Input.is_action_pressed("shift")
	
	# Apply appropriate gravity and terminal velocity
	var gravity_scale = fast_fall_gravity_scale if is_fast_falling else fall_gravity_scale
	var max_fall_velocity = fast_fall_terminal_velocity if is_fast_falling else terminal_velocity
	var air_speed_limit = fast_fall_air_speed if is_fast_falling else max_air_speed
	
	# Debug output for fast falling (can be removed later)
	if is_fast_falling and parent.velocity.y > 0:
		var fall_type = "crouch" if Input.is_action_pressed("crouch") else "shift"
		print("Fast falling with ", fall_type, "! Velocity: ", parent.velocity.y)
	
	# Gravity with clamp
	parent.velocity.y = min(
		parent.velocity.y + gravity * gravity_scale * delta,
		max_fall_velocity
	)

	# Horizontal control (reduced during fast fall)
	var axis := Input.get_axis("move_left","move_right")
	var target: float = axis * air_speed_limit

	if axis != 0:
		parent.velocity.x = move_toward(parent.velocity.x, target, air_accel * delta)
		parent.animations.flip_h = axis < 0
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, air_friction * delta)

	parent.move_and_slide()

	if parent.is_on_floor():
		return land_state

	return null
