extends State

@export var idle_state: State
@export var move_state: State

# -- Tunables ---------------------------------------------------------------
@export var idle_transition_vel: float = 50.0   # ← LOCAL here too
@export var land_duration: float = 0.10         # seconds “locked” in landing
@export var land_friction: float = 1200.0       # momentum bleed
# ---------------------------------------------------------------------------

var _t: float = 0.0

func enter() -> void:
	super()
	_t = 0.0
	# Optional: spawn landing particles, camera shake, etc.

func process_physics(delta: float) -> State:
	print("landing " + str(parent.velocity.x))
	_t += delta

	# Smoothly reduce leftover x-speed so big aerial dashes feel weighty
	parent.velocity.x = move_toward(parent.velocity.x, 0.0, land_friction * delta)
	parent.move_and_slide()

	if _t >= land_duration:
		if abs(parent.velocity.x) > idle_transition_vel:
			return move_state
		return idle_state

	return null
