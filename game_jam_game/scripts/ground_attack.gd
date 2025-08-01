extends State

# -- States -- #
@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var jump_state: State
@export var crouch_state: State
# -- Parameters -- #
@export var deceleration: float

var sword_anim: AnimationPlayer
var hitbox: HitBox

func enter() -> void:
	super()
	hitbox = parent.get_node("AnimatedSprite2D/Sword/Sprite2D/HitBox") as HitBox

func process_input(_event: InputEvent) -> State:
	sword_anim = parent.get_node("AnimatedSprite2D/Sword/AnimationPlayer") as AnimationPlayer

	# … then look at what the player is holding **right now**.
	if Input.is_action_pressed("up"):
		sword_anim.play("up_ward_swing")
		hitbox.attack_dir = "up"
		print("Playing Upward Swing Animation")
		return idle_state
	elif Input.is_action_pressed("crouch"): # or "down"
		sword_anim.play("down_ward_swing")
		hitbox.attack_dir = "down"
		print("Playing Downward Swing Animation")
		return crouch_state
	else:
		sword_anim.play("swing")
		hitbox.attack_dir = "side"
		print("Playing Swing Animation")
		return idle_state

	return null

func process_physics(delta: float) -> State:
	parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)
	parent.move_and_slide()
	return null

#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
#	print("Animation Finished, listening for other states")
#	if Input.get_axis("move_left", "move_right") != 0:
#		parent.state_machine.change_state(move_state)
#	else:
#		parent.state_machine.change_state(idle_state)
