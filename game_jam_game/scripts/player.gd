class_name Player

extends CharacterBody2D


@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: Node2D = $AnimatedSprite2D/Sword
@onready var camera: Camera2D = $Camera2D

@onready var state_machine: Node = $state_machine
var last_flip_h: bool = false
var original_sword_position: Vector2

func _ready() -> void:
	# Initialize the state machine, passing a reference of the player to the states,
	# that way they can move and react accordingly
	state_machine.init(self)
	# store the sword position and direction
	last_flip_h = animations.flip_h
	original_sword_position = sword.position


func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	state_machine.process_frame(delta)
	if animations.flip_h != last_flip_h:
		update_sword_position()

		last_flip_h = animations.flip_h

func update_sword_position() -> void:
	# Flip the sword's x position when the sprite flips
	if animations.flip_h:
		# Facing left - sword should be on the left side
		sword.scale.x = -1
		sword.position.x = -abs(sword.position.x)
	else:
		# Facing right - sword should be on the right side  
		sword.scale.x = 1
		sword.position.x = abs(sword.position.x)
