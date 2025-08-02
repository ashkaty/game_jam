extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var dash_state: State

# Air attack specific properties - movement effects removed
# @export var air_attack_gravity_scale: float = 1.5  # Removed: no longer affects gravity
# @export var air_attack_horizontal_damping: float = 0.8  # Removed: no longer affects horizontal movement
# @export var downward_attack_speed_boost: float = 400.0  # Removed: no longer affects downward velocity

var sword_anim: AnimationPlayer
# var initial_horizontal_velocity: float  # Removed: no longer needed

func enter() -> void:
	super()
	
	# Start cancelable action tracking
	parent.start_cancelable_action("air_attack")
	
	# No longer modifying horizontal velocity - let player maintain natural movement during air attacks
	

	

func process_input(_event: InputEvent):
	# Input processing moved to process_frame for polling system
	return null

func process_frame(delta: float) -> State:
	# Check for action cancellation first (air attacks are more restrictive)
	if parent.is_trying_to_cancel_with_dash() and dash_state and dash_state.is_dash_available():
		parent.end_current_action()
		return dash_state
	
	sword_anim = parent.get_node("AnimatedSprite2D/Sword/AnimationPlayer") as AnimationPlayer
	if parent.is_action_pressed_polling("up"):
		sword_anim.play("up_ward_swing")
		# print("Playing Upward Air Attack Animation")
		parent.end_current_action()
		return fall_state  # Return to falling after air attack
	elif parent.is_action_pressed_polling("crouch"):	# or "down"
		sword_anim.play("down_ward_swing")
		# print("Playing Downward Air Attack Animation")
		
		# No longer applying extra downward velocity - maintaining natural movement
		parent.end_current_action()
		return fall_state  # Return to falling after air attack
	else:
		sword_anim.play("swing")
		# print("Playing Attack Animation")
		parent.end_current_action()
		return fall_state  # Return to falling after air attack
	
	return null

func process_physics(delta: float) -> State:
	# Apply normal gravity during air attack - no longer modified
	parent.velocity.y += gravity * delta
	
	# Allow normal horizontal input during attack animation with enhanced responsiveness
	var input_axis: float = Input.get_axis("move_left", "move_right")
	if input_axis != 0.0:
		# Use the same enhanced air movement values as other air states for consistency
		var air_accel = 100.0  # Same as fall state
		var max_air_speed = 300.0  # Reasonable air speed limit
		var air_direction_change_multiplier = 1.5  # Same braking force as other air states
		var target_speed = input_axis * max_air_speed
		
		# Check if we're changing direction in air (input and current velocity have opposite signs)
		var is_changing_direction = (input_axis > 0 and parent.velocity.x < 0) or (input_axis < 0 and parent.velocity.x > 0)
		
		# Apply stronger braking force when changing directions in air
		var effective_air_accel = air_accel
		if is_changing_direction:
			effective_air_accel = air_accel * air_direction_change_multiplier
		
		parent.velocity.x = move_toward(parent.velocity.x, target_speed, effective_air_accel * delta)
		parent.animations.flip_h = input_axis < 0
	else:
		# Apply air friction when no input (same as other air states)
		var air_friction = 200.0
		parent.velocity.x = move_toward(parent.velocity.x, 0.0, air_friction * delta)
	
	parent.move_and_slide()
	
	# If we land during the attack, transition to ground attack or idle
	if parent.is_on_floor():
		# Let the animation finish, but we're now on ground
		return null  # Stay in air attack until animation finishes
	
	return null

#func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	#print("Air Attack Animation Finished")
	#
	## Check if we're on the ground or still in air
	#if parent.is_on_floor():
		## We landed during or after the attack
		#if Input.get_axis("move_left", "move_right") != 0:
			#parent.state_machine.change_state(move_state)
		#else:
			#parent.state_machine.change_state(idle_state)
	#else:
		## Still in air, return to falling
		#parent.state_machine.change_state(fall_state)
