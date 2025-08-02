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

# Movement variables
@export var move_speed: float = 100.0
@export var patrol_range: float = 200.0  # How far the enemy patrols
@export var chase_range: float = 300.0   # How far the enemy will chase the player
@export var return_to_patrol_range: float = 400.0  # Distance at which enemy stops chasing and returns

# Attack variables
@export var attack_range: float = 60.0   # Distance at which enemy can attack
@export var attack_damage: int = 1  # Changed to 1 to take 1 heart per hit
@export var attack_cooldown: float = 1.5 # Seconds between attacks
@export var attack_knockback_force: float = 300.0
@export var attack_state_duration: float = 0.8  # Minimum time to stay in attack state
@export var attack_state_exit_range: float = 80.0  # Slightly larger than attack_range to prevent rapid state switching

# Passive body damage variables
@export var passive_body_damage_enabled: bool = true  # Whether touching enemy damages player
@export var passive_body_damage: int = 1  # Damage dealt by touching enemy body
@export var passive_damage_cooldown: float = 1.0  # Cooldown between passive damage instances

# AI State variables
enum EnemyState { PATROL, CHASE, ATTACK, RETURN_TO_PATROL }
var current_state: EnemyState = EnemyState.PATROL
var patrol_start_position: Vector2
var patrol_direction: int = 1  # 1 for right, -1 for left
var attack_timer: float = 0.0
var attack_state_timer: float = 0.0  # Timer to prevent rapid attack state switching
var passive_damage_timer: float = 0.0  # Timer for passive damage cooldown
var player: CharacterBody2D = null
var last_known_player_position: Vector2
var is_attacking: bool = false  # Flag to prevent multiple simultaneous attacks

func _ready():
	# Add the enemy to a group so other systems can find it
	add_to_group("enemies")
	current_health = max_health
	patrol_start_position = global_position
	
	# Enable the passive body hitbox
	_setup_passive_body_hitbox()
	
	# Find the player (assuming there's only one player in the scene)
	# Try multiple approaches to find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Enemy found player: ", player.name)
	else:
		print("Warning: No player found in 'player' group. Searching for Player node...")
		# Search the scene tree for a Player node
		var scene_root = get_tree().current_scene
		if scene_root:
			player = _find_player_recursive(scene_root)
			if player:
				print("Enemy found player by search: ", player.name)
			else:
				print("Warning: No player found! Enemy will only patrol.")
	
	print("Enemy _ready() called - Health: ", current_health)
	print("Enemy position: ", global_position)
	print("Enemy is_on_floor(): ", is_on_floor())
	print("Enemy patrol start position: ", patrol_start_position)

# Recursive function to find player
func _find_player_recursive(node: Node) -> CharacterBody2D:
	# Check if this node is the player by name
	if node.name == "Player":
		return node as CharacterBody2D
	
	# Check if this node has a script that contains "player"
	if node.get_script() != null:
		var script = node.get_script()
		var script_path = script.get_path() if script else ""
		if "player.gd" in script_path.to_lower():
			return node as CharacterBody2D
	
	# Check children recursively
	for child in node.get_children():
		var result = _find_player_recursive(child)
		if result:
			return result
	
	return null

# Setup the passive body hitbox for contact damage
func _setup_passive_body_hitbox():
	var body_hitbox = get_node_or_null("BodyHitBox")
	if body_hitbox:
		# Set damage values for the passive hitbox
		body_hitbox.damage = passive_body_damage
		body_hitbox.knockback_multiplier = 200.0  # Lighter knockback for passive contact
		
		# Enable the collision shape
		var collision_shape = body_hitbox.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.disabled = false if passive_body_damage_enabled else true
			print("Enemy passive body hitbox configured - damage: ", passive_body_damage, ", enabled: ", passive_body_damage_enabled)
		else:
			print("Warning: BodyHitBox CollisionShape2D not found")
	else:
		print("Warning: BodyHitBox not found in enemy scene")

# Toggle passive body damage on/off
func set_passive_body_damage_enabled(enabled: bool):
	passive_body_damage_enabled = enabled
	var body_hitbox = get_node_or_null("BodyHitBox")
	if body_hitbox:
		var collision_shape = body_hitbox.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.disabled = not enabled
			print("Enemy passive body damage ", "enabled" if enabled else "disabled")

func _physics_process(delta):
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update attack state timer
	if attack_state_timer > 0:
		attack_state_timer -= delta
	
	# Update passive damage timer
	if passive_damage_timer > 0:
		passive_damage_timer -= delta
	
	# Debug output (more frequent for better visibility)
	if randf() < 0.05:  # 5% chance each frame to see debug info more often
		print("Enemy Debug - Position: ", global_position, " | Velocity: ", velocity.round(), " | On floor: ", is_on_floor(), " | State: ", get_current_state_name(), " | Player found: ", player != null)
		if player:
			print("  Distance to player: ", global_position.distance_to(player.global_position))
	
	# AI behavior based on current state
	update_ai_behavior(delta)
	
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
		# Cap falling speed to prevent excessive velocity
		velocity.y = min(velocity.y, 2000.0)
	
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
				if randf() < 0.1:  # Occasional debug for wall collisions
					print("Enemy pushed away from wall, penetration: ", penetration_depth)
	
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

# AI Behavior System
func update_ai_behavior(delta: float):
	# Re-try finding player if we don't have one
	if not player or not is_instance_valid(player):
		_try_find_player()
	
	# If still no player found, just patrol
	if not player or not is_instance_valid(player):
		patrol_behavior()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Debug state transitions occasionally
	var old_state = current_state
	
	match current_state:
		EnemyState.PATROL:
			patrol_behavior()
			# Check if player is within chase range
			if distance_to_player <= chase_range:
				current_state = EnemyState.CHASE
				last_known_player_position = player.global_position
				print("Enemy switching from PATROL to CHASE - Player distance: ", distance_to_player)
		
		EnemyState.CHASE:
			chase_behavior()
			# Check if player is within attack range and we're not already in attack cooldown
			if distance_to_player <= attack_range and attack_timer <= 0:
				current_state = EnemyState.ATTACK
				attack_state_timer = attack_state_duration  # Set minimum attack state duration
				print("Enemy switching from CHASE to ATTACK - Player distance: ", distance_to_player)
			# Check if player is too far away
			elif distance_to_player > return_to_patrol_range:
				current_state = EnemyState.RETURN_TO_PATROL
				print("Enemy switching from CHASE to RETURN_TO_PATROL - Player distance: ", distance_to_player)
			else:
				last_known_player_position = player.global_position
		
		EnemyState.ATTACK:
			attack_behavior()
			# Only exit attack state if minimum duration has passed and player is far enough
			if attack_state_timer <= 0 and distance_to_player > attack_state_exit_range:
				if distance_to_player <= chase_range:
					current_state = EnemyState.CHASE
					print("Enemy switching from ATTACK to CHASE - Player distance: ", distance_to_player)
				else:
					current_state = EnemyState.RETURN_TO_PATROL
					print("Enemy switching from ATTACK to RETURN_TO_PATROL - Player distance: ", distance_to_player)
		
		EnemyState.RETURN_TO_PATROL:
			return_to_patrol_behavior()
			# Check if we're back to patrol area
			if global_position.distance_to(patrol_start_position) <= 50.0:
				current_state = EnemyState.PATROL
				print("Enemy returned to patrol area")
			# Check if player comes back within chase range
			elif distance_to_player <= chase_range:
				current_state = EnemyState.CHASE
				print("Enemy switching from RETURN_TO_PATROL to CHASE - Player returned: ", distance_to_player)

# Helper function to try finding the player
func _try_find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Enemy found player: ", player.name)
	else:
		# Alternative: search for node by class name
		var scene_root = get_tree().current_scene
		if scene_root:
			player = _find_player_recursive(scene_root)
			if player:
				print("Enemy found player by search: ", player.name)

func patrol_behavior():
	# Simple back and forth patrol
	var distance_from_start = global_position.x - patrol_start_position.x
	
	# Check if we've reached the patrol limits
	if distance_from_start >= patrol_range:
		patrol_direction = -1
		if randf() < 0.1:
			print("Enemy reached right patrol limit, turning left")
	elif distance_from_start <= -patrol_range:
		patrol_direction = 1
		if randf() < 0.1:
			print("Enemy reached left patrol limit, turning right")
	
	# Move in patrol direction
	velocity.x = patrol_direction * move_speed
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = patrol_direction < 0
	
	# Debug patrol occasionally
	if randf() < 0.02:
		print("Patrolling - Distance from start: ", distance_from_start, " | Direction: ", patrol_direction, " | Range: ", patrol_range)

func chase_behavior():
	# Move towards the player
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * move_speed * 1.5  # Move faster when chasing
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = direction_to_player.x < 0

func attack_behavior():
	# Stop moving and attack
	velocity.x = 0
	
	# Face the player
	if sprite and player:
		var direction_to_player = (player.global_position - global_position).normalized()
		sprite.flip_h = direction_to_player.x < 0
	
	# Attack if cooldown is ready and not already attacking
	if attack_timer <= 0 and not is_attacking:
		perform_attack()
		attack_timer = attack_cooldown

func return_to_patrol_behavior():
	# Move back towards patrol start position
	var direction_to_start = (patrol_start_position - global_position).normalized()
	velocity.x = direction_to_start.x * move_speed
	
	# Flip sprite based on direction
	if sprite:
		sprite.flip_h = direction_to_start.x < 0

func perform_attack():
	print("Enemy attacking!")
	is_attacking = true  # Set flag to prevent multiple simultaneous attacks
	
	# Play attack animation if available
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Create a temporary hitbox for the attack
	create_attack_hitbox()
	
	# Reset attack flag after a short delay to allow for next attack
	var reset_timer = Timer.new()
	reset_timer.wait_time = 0.5  # Half second before allowing next attack
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_on_attack_reset)
	add_child(reset_timer)
	reset_timer.start()
	
	# Check if player is still in range and deal damage (fallback if hitbox system fails)
	if player and global_position.distance_to(player.global_position) <= attack_range:
		# This is a fallback - the hitbox system should handle damage normally
		print("Player in attack range - hitbox should handle damage")

func _on_attack_reset():
	is_attacking = false
	print("Attack flag reset - ready for next attack")

func create_attack_hitbox():
	# Check if there's already an active attack hitbox
	var existing_hitbox = get_node_or_null("AttackHitbox")
	if existing_hitbox:
		print("Attack hitbox already exists, skipping creation")
		return
	
	# Create a temporary hitbox for this attack
	var hitbox_area = Area2D.new()
	var hitbox_collision = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	
	# Name the hitbox for identification
	hitbox_area.name = "AttackHitbox"
	
	# Name the collision shape so the hitbox script can find it
	hitbox_collision.name = "CollisionShape2D"
	
	# Set up the collision shape first
	hitbox_shape.size = Vector2(attack_range, 40)  # Width = attack range, height = 40
	hitbox_collision.shape = hitbox_shape
	
	# Position the hitbox in front of the enemy
	var hitbox_offset = Vector2(attack_range * 0.5, 0)
	if sprite and sprite.flip_h:
		hitbox_offset.x = -hitbox_offset.x
	
	hitbox_collision.position = hitbox_offset
	
	# Add collision to hitbox area first
	hitbox_area.add_child(hitbox_collision)
	
	# Set collision layers properly for hitboxes
	hitbox_area.collision_layer = 4  # Layer 4 for hitboxes
	hitbox_area.collision_mask = 0   # Don't detect anything
	
	# Try to load the hitbox script
	var hitbox_script = load("res://scripts/hit_hurt_boxes/hitbox.gd")
	if hitbox_script:
		hitbox_area.set_script(hitbox_script)
		
		# Set up the hitbox properties after the script is set
		hitbox_area.damage = attack_damage
		hitbox_area.knockback_multiplier = attack_knockback_force
	else:
		print("Warning: Could not load hitbox script, using basic Area2D")
	
	# Add hitbox to the scene tree
	add_child(hitbox_area)
	
	print("Created attack hitbox at offset: ", hitbox_offset, " with size: ", hitbox_shape.size)
	
	# Remove the hitbox after a short duration
	var timer = Timer.new()
	timer.wait_time = 0.3  # Hitbox active for 0.3 seconds (slightly longer for better hit detection)
	timer.one_shot = true
	timer.timeout.connect(_on_attack_hitbox_timeout.bind(hitbox_area))
	add_child(timer)
	timer.start()

func _on_attack_hitbox_timeout(hitbox_area: Area2D):
	if hitbox_area and is_instance_valid(hitbox_area):
		hitbox_area.queue_free()

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
	# Interrupt attack if currently attacking
	if current_state == EnemyState.ATTACK:
		current_state = EnemyState.CHASE
		attack_timer = attack_cooldown * 0.5  # Reduced cooldown after being hit
	
	# Apply knockback with resistance factor
	var actual_knockback = knockback_vector * knockback_resistance
	
	# Clamp to maximum knockback velocity
	if actual_knockback.length() > max_knockback_velocity:
		actual_knockback = actual_knockback.normalized() * max_knockback_velocity
	
	velocity += actual_knockback

# Utility functions for enemy AI
func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return INF

func is_player_in_range(range_distance: float) -> bool:
	return get_distance_to_player() <= range_distance

func get_current_state_name() -> String:
	match current_state:
		EnemyState.PATROL:
			return "PATROL"
		EnemyState.CHASE:
			return "CHASE"
		EnemyState.ATTACK:
			return "ATTACK"
		EnemyState.RETURN_TO_PATROL:
			return "RETURN_TO_PATROL"
		_:
			return "UNKNOWN"

# Method to manually set enemy state (useful for debugging or special events)
func set_enemy_state(new_state: EnemyState):
	current_state = new_state
	match new_state:
		EnemyState.ATTACK:
			attack_timer = 0  # Reset attack timer when forced into attack state
		EnemyState.PATROL:
			# Reset patrol direction based on position relative to start
			var distance_from_start = global_position.x - patrol_start_position.x
			patrol_direction = 1 if distance_from_start < 0 else -1

# Utility methods for passive body damage
func is_passive_damage_enabled() -> bool:
	"""Check if passive body damage is currently enabled"""
	return passive_body_damage_enabled

func get_passive_damage_amount() -> int:
	"""Get the amount of damage dealt by touching enemy body"""
	return passive_body_damage

func set_passive_damage_amount(damage: int):
	"""Set the passive body damage amount"""
	passive_body_damage = damage
	var body_hitbox = get_node_or_null("BodyHitBox")
	if body_hitbox:
		body_hitbox.damage = damage
		print("Enemy passive body damage set to: ", damage)
