extends State

@export var idle_state: State
@export var move_state: State

# -- Tunables ---------------------------------------------------------------
@export var idle_transition_vel: float = 50.0   # ← LOCAL here too
@export var land_duration: float = 0.10         # seconds "locked" in landing
@export var land_friction: float = 1200.0       # momentum bleed
@export var crouch_land_friction: float = 2400.0  # much higher friction when landing while crouching
# ---------------------------------------------------------------------------

var _t: float = 0.0

func enter() -> void:
	super()
	_t = 0.0
	# Optional: spawn landing particles, camera shake, etc.

func process_physics(delta: float) -> State:
	print("landing " + str(parent.velocity.x))
	_t += delta

	# Check if player is holding crouch for reduced sliding
	var is_crouching = parent.is_action_pressed_polling("crouch")
	var friction_to_use = crouch_land_friction if is_crouching else land_friction
	
	# Smoothly reduce leftover x-speed so big aerial dashes feel weighty
	# Use higher friction when crouching to reduce sliding
	parent.velocity.x = move_toward(parent.velocity.x, 0.0, friction_to_use * delta)
	parent.move_and_slide()

	if _t >= land_duration:
		if abs(parent.velocity.x) > idle_transition_vel:
			return move_state
		return idle_state

	return null

# -- Tunables ---------------------------------------------------------------
#@export var idle_transition_vel: float = 50.0   # ← LOCAL here too
#@export var land_duration: float = 0.10         # seconds "locked" in landing
#@export var land_friction: float = 1200.0       # momentum bleed
#@export var crouch_land_friction: float = 2400.0  # much higher friction when landing while crouching
# ---------------------------------------------------------------------------

# -- Tunables ---------------------------------------------------------------
#@export var idle_transition_vel: float = 50.0   # ← LOCAL here too
#@export var land_duration: float = 0.10         # seconds “locked” in landing
#@export var land_friction: float = 1200.0       # momentum bleed
# ---------------------------------------------------------------------------

#func process_physics(delta: float) -> State:
#	print("landing " + str(parent.velocity.x))
#	_t += delta

	# Check if player is holding crouch or shift for reduced sliding
#	var is_crouching = Input.is_action_pressed("crouch") or Input.is_action_pressed("shift")
#	var friction_to_use = crouch_land_friction if is_crouching else land_friction
	
	# Smoothly reduce leftover x-speed so big aerial dashes feel weighty
	# Use higher friction when crouching to reduce sliding
#	parent.velocity.x = move_toward(parent.velocity.x, 0.0, friction_to_use * delta)
#	parent.move_and_slide()

#	if _t >= land_duration:
#		if abs(parent.velocity.x) > idle_transition_vel:
#			return move_state
#		return idle_state

#	return null
