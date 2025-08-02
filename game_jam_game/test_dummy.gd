extends CharacterBody2D

@onready var animation_player := $AnimationPlayer

# Physics variables
@export var gravity: float = 980.0  # Standard gravity
@export var friction: float = 0.8   # Ground friction for sliding
@export var air_friction: float = 0.98  # Air resistance

# Knockback variables
@export var knockback_resistance: float = 1.0  # How much knockback to apply (0.0 = no knockback, 1.0 = full knockback)
@export var max_knockback_velocity: float = 800.0  # Maximum knockback speed
@export var min_velocity_threshold: float = 10.0  # Minimum velocity to continue moving

# Health and status
@export var max_health: int = 100
var current_health: int = 100

func _ready():
	# Add the dummy to a group so other systems can find it
	add_to_group("enemies")
	current_health = max_health

func _physics_process(delta):
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Apply friction/air resistance
	if is_on_floor():
		# Ground friction
		velocity.x *= friction
		if abs(velocity.x) < min_velocity_threshold:
			velocity.x = 0.0
	else:
		# Air resistance
		velocity *= air_friction
	
	# Move with physics and handle collisions
	move_and_slide()

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	animation_player.play("hurt")
	print("Dummy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func apply_knockback(knockback_force: Vector2):
	"""Apply knockback force to the dummy with physics"""
	# Scale the knockback by resistance (allows for different enemy types)
	var applied_knockback = knockback_force * knockback_resistance
	
	# Add the knockback to current velocity (accumulative)
	velocity += applied_knockback
	
	# Clamp to maximum knockback velocity to prevent physics breaking
	velocity.x = clamp(velocity.x, -max_knockback_velocity, max_knockback_velocity)
	velocity.y = clamp(velocity.y, -max_knockback_velocity, max_knockback_velocity)
	
	print("Dummy received knockback: ", knockback_force, " | Applied: ", applied_knockback, " | New velocity: ", velocity)

func die():
	print("Test Dummy destroyed!")
	# You could add death animation here
	# queue_free()  # Uncomment if you want dummy to disappear when killed
