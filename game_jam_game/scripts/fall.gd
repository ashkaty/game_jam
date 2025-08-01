extends State

@export var land_state: State
@export var move_state: State
@export var idle_state: State

# ---- Tunables --------------------------------------------------------
@export var fall_gravity_scale: float = 2.6
@export var terminal_velocity: float  = 1200.0
@export var air_accel: float          = 600.0
@export var air_friction: float       = 300.0
@export var max_air_speed: float      = 220.0
# ----------------------------------------------------------------------

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
