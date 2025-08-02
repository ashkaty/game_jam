extends CharacterBody2D

@onready var animation_player := $AnimationPlayer
@onready var sprite := $Sprite2D

# Physics variables (same as test_dummy for consistency)
@export var gravity: float = 980.0  # Standard gravity
@export var friction: float = 0.8   # Ground friction for sliding
@export var air_friction: float = 0.98  # Air resistance

# Collision prevention
@export var collision_safety_margin: float = 2.0  # Extra margin to prevent getting stuck
@export var max_horizontal_penetration: float = 5.0  # Max allowed horizontal penetration before correction

# Knockback variables
@export var knockback_resistance: float = 1.0  # How much knockback to apply (0.0 = no knockback, 1.0 = full knockback)
@export var max_knockback_velocity: float = 800.0  # Maximum knockback speed
@export var min_velocity_threshold: float = 10.0  # Minimum velocity to continue moving

# Health and status
@export var max_health: int = 50
var current_health: int = 50

func _ready():
	# Add the enemy to a group so other systems can find it
	add_to_group("enemies")
	current_health = max_health
	print("Enemy _ready() called - Health: ", current_health)
	print("Enemy position: ", global_position)
	print("Enemy is_on_floor(): ", is_on_floor())

func _physics_process(delta):
	# Debug output
	if randf() < 0.01:  # Only print occasionally to avoid spam
		print("Enemy physics - Position: ", global_position, " Velocity: ", velocity, " On floor: ", is_on_floor())
	
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
		if randf() < 0.01:
			print("Applying gravity - New velocity.y: ", velocity.y)
	
	# Check for and resolve horizontal collisions to prevent getting jammed
	if is_on_wall():
		# Detect if enemy is penetrating into wall geometry
		var collision_info = move_and_collide(Vector2.ZERO, true)
		if collision_info:
			var penetration_depth = collision_info.get_travel().length()
			if penetration_depth > max_horizontal_penetration:
				# Push enemy away from wall to prevent jamming
				var push_direction = collision_info.get_normal()
				global_position += push_direction * (collision_safety_margin + penetration_depth)
				velocity.x *= 0.5  # Reduce horizontal velocity to prevent bouncing
	
	# Apply friction/air resistance
	if is_on_floor():
		# Ground friction
		velocity.x *= friction
		if abs(velocity.x) < min_velocity_threshold:
			velocity.x = 0.0
	else:
		# Air resistance
		velocity.x *= air_friction
	
	# Apply the movement
	move_and_slide()
	
	# Additional safety check: if enemy is still overlapping significantly, move it out
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision and collision.get_travel().length() > max_horizontal_penetration:
				# Force push away from collision
				global_position += collision.get_normal() * collision_safety_margin

# Damage system (called by HurtBox)
func take_damage(damage_amount: int) -> void:
	current_health = max(0, current_health - damage_amount)
	animation_player.play("hurt")
	print("Enemy took ", damage_amount, " damage! Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die():
	print("Enemy defeated!")
	# You can add death effects here (particles, sound, etc.)
	queue_free()

# Apply knockback when hit
func apply_knockback(knockback_vector: Vector2):
	# Apply knockback with resistance factor
	var actual_knockback = knockback_vector * knockback_resistance
	
	# Clamp to maximum knockback velocity
	if actual_knockback.length() > max_knockback_velocity:
		actual_knockback = actual_knockback.normalized() * max_knockback_velocity
	
	velocity += actual_knockback
