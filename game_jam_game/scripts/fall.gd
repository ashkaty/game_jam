extends State

@export var land_state: State
@export var move_state: State
@export var idle_state: State
@export var air_attack_state: State
@export var crouch_state: State

# ---- Tunables --------------------------------------------------------
@export var fall_gravity_scale: float = 2.6
@export var terminal_velocity: float  = 1200.0
@export var air_accel: float          = 600.0
@export var air_friction: float       = 300.0
@export var max_air_speed: float      = 220.0
@export var sword_offset_y: float     = -15.0  # How much to move sword up during fall
# ----------------------------------------------------------------------

var original_sword_position: Vector2

func enter() -> void:
	super()
	# Store original sword position and move it up slightly during fall
	if parent.sword:
		original_sword_position = parent.sword.position
		parent.sword.position = original_sword_position + Vector2(0, sword_offset_y)

func exit() -> void:
	# Reset sword position when exiting fall, but let player handle direction
	if parent.sword:
		parent.sword.position.y = original_sword_position.y  # Reset Y position only
		parent.update_sword_position()  # Let the player handle X position based on current facing direction

func process_input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed('attack'):
		return air_attack_state
	if Input.is_action_just_pressed('crouch'):
		return crouch_state
	return null

func process_physics(delta: float) -> State:
	# Gravity with clamp
	parent.velocity.y = min(
		parent.velocity.y + gravity * fall_gravity_scale * delta,
		terminal_velocity
	)

	# Horizontal control
	var axis := Input.get_axis("move_left","move_right")
	var target := axis * max_air_speed

	if axis != 0:
		parent.velocity.x = move_toward(parent.velocity.x, target, air_accel * delta)
		parent.animations.flip_h = axis < 0
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, air_friction * delta)

	parent.move_and_slide()

	if parent.is_on_floor():
		return land_state

	return null
