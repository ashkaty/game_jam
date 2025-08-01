extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State

# Air attack specific properties
@export var air_attack_gravity_scale: float = 1.5  # Slightly reduced gravity during air attack
@export var air_attack_horizontal_damping: float = 0.8  # Reduce horizontal movement during attack

var sword_anim: AnimationPlayer
var initial_horizontal_velocity: float
var hitbox: HitBox

func enter() -> void:
		super()
	
	
	
		hitbox = parent.get_node("AnimatedSprite2D/Sword/Sprite2D/HitBox") as HitBox

		# Store initial horizontal velocity and apply damping
		initial_horizontal_velocity = parent.velocity.x
		parent.velocity.x *= air_attack_horizontal_damping
	

	

func process_input(_event: InputEvent):
	sword_anim = parent.get_node("AnimatedSprite2D/Sword/AnimationPlayer") as AnimationPlayer
	if Input.is_action_pressed("up"):
		sword_anim.play("up_ward_swing")
		hitbox.attack_dir = "up"
		print("Playing Upward Air Attack Animation")
		return idle_state
	elif Input.is_action_pressed("crouch"):	# or "down"
		sword_anim.play("down_ward_swing")
		hitbox.attack_dir = "down"
		print("Playing Downward Air Attak Animation")
		return idle_state
	else:
		sword_anim.play("swing")
		hitbox.attack_dir = "side"
		print("Playing Attack Animation")
		return idle_state

func process_physics(delta: float) -> State:
	# Apply reduced gravity during air attack
	parent.velocity.y += gravity * air_attack_gravity_scale * delta
	
	# Maintain reduced horizontal movement during attack
	# Don't allow new horizontal input during attack animation
	
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
