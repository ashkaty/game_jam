extends State

# -- States -- #
@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var jump_state: State
@export var crouch_state: State
@export var dash_state: State
# -- Parameters -- #
@export var deceleration: float

var sword_anim: AnimationPlayer



func enter() -> void:
	super()
	
	# Start cancelable action tracking
	parent.start_cancelable_action("ground_attack")
	
	#var sword_hitbox = parent.get_node("Sword/Sprite/Hitbox")  as Area2D

func process_input(_event: InputEvent) -> State:
	# Input processing moved to process_frame for polling system
	return null

func process_frame(delta: float) -> State:
	# Check for action cancellation first
	if parent.is_trying_to_cancel_with_movement():
		parent.end_current_action()
		return move_state
	
	if parent.is_trying_to_cancel_with_jump() and parent.can_jump():
		parent.end_current_action()
		return jump_state
	
	if parent.is_trying_to_cancel_with_dash() and dash_state and dash_state.is_dash_available():
		parent.end_current_action()
		return dash_state
	
	sword_anim = parent.get_node("AnimatedSprite2D/Sword/AnimationPlayer") as AnimationPlayer
	
	# Then look at what the player is holding **right now**.
	if parent.is_action_pressed_polling("up"):
		sword_anim.play("up_ward_swing")
		print("Playing Upward Swing Animation")
		parent.end_current_action()
		return idle_state
	elif parent.is_action_pressed_polling("crouch"):	# or "down"
		sword_anim.play("down_ward_swing")
		print("Playing Downward Swing Animation")
		parent.end_current_action()
		return crouch_state
	else:
		sword_anim.play("swing")
		print("Playing Swing Animation")
		parent.end_current_action()
		return idle_state

	return null
		
		 


func process_physics(delta: float) -> State:
	parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)
	parent.move_and_slide()
	return null


	# for example: if the player is holding left/right, go back to Move, else Idle
	
		
		


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print("Animation Finished, listening for other states")
	#if Input.get_axis("move_left", "move_right") != 0:
		#parent.state_machine.change_state(move_state)
	#else:
		#parent.state_machine.change_state(idle_state)
