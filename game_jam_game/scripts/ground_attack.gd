extends State

@export var idle_state: State

@export var move_state: State

@export var fall_state: State

@export var jump_state: State

@export var deceleration: float

var sword_anim: AnimationPlayer
#@onready var sword_anim = parent.get_node("AnimatedSprite2D/Sword")
#@onready var sword_hitbox = parent.get_node("Sword/Sprite/Hitbox")  # adjust path


func enter() -> void:
	super()
	
	sword_anim = parent.get_node("AnimatedSprite2D/Sword/AnimationPlayer") as AnimationPlayer
	
	
	sword_anim.play("swing")
	print("Playing Animation")
	#var sword_hitbox = parent.get_node("Sword/Sprite/Hitbox")  as Area2D

func process_physics(delta: float) -> State:
	parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)
	parent.move_and_slide()
	return null


	# for example: if the player is holding left/right, go back to Move, else Idle
	
		
		


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("Animation Finished, listening for other states")
	if Input.get_axis("move_left", "move_right") != 0:
		parent.state_machine.change_state(move_state)
	else:
		parent.state_machine.change_state(idle_state)
