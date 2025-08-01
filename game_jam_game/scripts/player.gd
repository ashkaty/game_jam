class_name Player

extends CharacterBody2D


@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: Node2D = $AnimatedSprite2D/Sword
@onready var camera: Camera2D = $Camera2D

@onready var state_machine: Node = $state_machine
var last_flip_h: bool = false
var original_sword_position: Vector2

# Player stats for UI display
var health: int = 100
var max_health: int = 100
var score: int = 0
var player_level: int = 1
var experience: int = 0

# Coyote time variables
@export var coyote_time_duration: float = 0.5  # Time window for coyote jump
var coyote_timer: float = 0.0
var was_on_floor: bool = false
var coyote_available: bool = false  # Track if coyote time should be available

func _ready() -> void:
	# Initialize the state machine, passing a reference of the player to the states,
	# that way they can move and react accordingly
	state_machine.init(self)
	# store the sword position and direction
	last_flip_h = animations.flip_h
	original_sword_position = sword.position
	# Initialize coyote time state
	was_on_floor = is_on_floor()
	coyote_timer = coyote_time_duration if was_on_floor else 0.0
	coyote_available = was_on_floor
	
	# Add player to a group so the UI can find it
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	# Update coyote time BEFORE state machine processing
	update_coyote_time(delta)
	
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

func update_coyote_time(delta: float) -> void:
	var currently_on_floor = is_on_floor()
	
	if currently_on_floor:
		# Reset timer and availability when on ground
		coyote_timer = coyote_time_duration
		coyote_available = true
		if not was_on_floor:
			print("Landed on ground - coyote reset")
	else:
		# Only start the message when we first leave the ground
		if was_on_floor:
			print("LEFT GROUND! Coyote timer: ", coyote_timer, " Available: ", coyote_available)
		
		# Count down when in air, but only if coyote is available
		if coyote_available and coyote_timer > 0.0:
			coyote_timer = max(0.0, coyote_timer - delta)
			if coyote_timer <= 0.0:
				print("COYOTE TIME EXPIRED!")
				coyote_available = false
	
	was_on_floor = currently_on_floor

func can_coyote_jump() -> bool:
	var can_jump = coyote_available and coyote_timer > 0.0
	
	if can_jump and not is_on_floor():
		print("Coyote time jump activated! Timer: ", coyote_timer)
		
	return can_jump

# Player stats getter methods for UI
func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func get_score() -> int:
	return score

func get_level() -> int:
	return player_level

func get_experience() -> int:
	return experience

# Player stats setter methods
func set_health(new_health: int):
	health = clamp(new_health, 0, max_health)

func set_max_health(new_max_health: int):
	max_health = max(1, new_max_health)
	health = min(health, max_health)

func add_score(points: int):
	score += points

func add_experience(exp: int):
	experience += exp
	check_level_up()

func damage(amount: int):
	set_health(health - amount)
	if health <= 0:
		die()

func heal(amount: int):
	set_health(health + amount)

func die():
	print("Player died!")
	# Add death logic here

func check_level_up():
	var exp_needed = player_level * 100  # Simple leveling formula
	if experience >= exp_needed:
		player_level += 1
		experience -= exp_needed
		print("Level up! Now level ", player_level)
