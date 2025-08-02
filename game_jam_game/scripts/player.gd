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
@export var coyote_time_duration: float = 0.25  # Time window for coyote jump
var coyote_timer: float = 0.0
var was_on_floor: bool = false
var coyote_available: bool = false  # Track if coyote time should be available
var jumped_off_ground: bool = false  # Track if player jumped off ground (vs walked off)

# Jump cooldown variables
@export var jump_cooldown_duration: float = 0.15  # Time before allowing another jump after landing
var jump_cooldown_timer: float = 0.0
var can_jump_again: bool = true

# Jump buffer variables
@export var jump_buffer_duration: float = 0.15  # Time window to buffer jump input
var jump_buffer_timer: float = 0.0
var has_buffered_jump: bool = false

# Head bonk mechanic variables
@export var head_bonk_speed_boost: float = 300.0  # Horizontal speed added when hitting head
@export var head_bonk_grace_period: float = 0.1   # Time after jump start to allow head bonk
@export var head_bonk_vertical_impulse: float = 50.0  # Small downward push after bonk
@export var head_bonk_minimum_upward_velocity: float = -100.0  # Must be moving up fast enough
var last_head_bonk_time: float = 0.0
var head_bonk_cooldown: float = 0.3  # Prevent multiple bonks in quick succession
var total_time: float = 0.0  # Track total game time

# Fast fall damage mechanic variables
@export var fast_fall_damage_multiplier: float = 1.5  # Damage multiplier when fast falling
@export var fast_fall_minimum_speed: float = 800.0  # Minimum fall speed to trigger bonus damage
@export var max_fast_fall_damage_multiplier: float = 4.0  # Maximum damage multiplier at terminal velocity

# Signal for head bonk events (can be connected to by UI, particles, etc.)
signal head_bonk_occurred(boost_amount: float, direction: int)

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
	
	# Initialize jump cooldown state
	jump_cooldown_timer = 0.0
	can_jump_again = true
	
	# Initialize jump buffer state
	has_buffered_jump = false
	jump_buffer_timer = 0.0
	
	# Add player to a group so the UI can find it
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	# Update total time for head bonk tracking
	total_time += delta
	
	# Update jump cooldown timer
	if jump_cooldown_timer > 0.0:
		jump_cooldown_timer -= delta
		if jump_cooldown_timer <= 0.0:
			can_jump_again = true
			print("Jump cooldown expired - can jump again")
	
	# Update jump buffer timer
	if has_buffered_jump:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0.0:
			has_buffered_jump = false
			print("Jump buffer expired")
	
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
		
		# Only start jump cooldown if we landed after jumping off ground
		if not was_on_floor and jumped_off_ground:
			print("Landed on ground after jumping - starting jump cooldown")
			jump_cooldown_timer = jump_cooldown_duration
			can_jump_again = false
		elif not was_on_floor:
			print("Landed on ground after walking off - no jump cooldown")
		
		jumped_off_ground = false  # Reset jump flag when landing
	else:
		# Only start the message when we first leave the ground
		if was_on_floor:
			print("LEFT GROUND! Jumped: ", jumped_off_ground, " Coyote timer: ", coyote_timer, " Available: ", coyote_available)
			
			# If player jumped off ground, disable coyote time immediately
			if jumped_off_ground:
				coyote_available = false
				coyote_timer = 0.0
				print("Coyote time disabled - player jumped off ground")
		
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

# Called by jump state to mark that player jumped off ground
func mark_jumped_off_ground():
	jumped_off_ground = true
	print("Player jumped off ground - coyote time disabled")

# Check if player can perform a normal ground jump
func can_ground_jump() -> bool:
	return is_on_floor() and can_jump_again

# Check if player can perform any type of jump (ground or coyote)
func can_jump() -> bool:
	return can_ground_jump() or can_coyote_jump()

# Buffer a jump input for later execution
func buffer_jump():
	has_buffered_jump = true
	jump_buffer_timer = jump_buffer_duration
	print("Jump buffered! Timer: ", jump_buffer_timer)

# Check if there's a buffered jump that should be executed
func has_valid_jump_buffer() -> bool:
	return has_buffered_jump and jump_buffer_timer > 0.0

# Consume the jump buffer (call this when a buffered jump is executed)
func consume_jump_buffer():
	has_buffered_jump = false
	jump_buffer_timer = 0.0
	print("Jump buffer consumed!")

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

# Fast fall damage calculation
func get_fast_fall_damage_multiplier() -> float:
	# Check if player is fast falling (holding crouch or shift) and moving downward fast enough
	var is_fast_falling = Input.is_action_pressed("crouch") or Input.is_action_pressed("shift")
	
	if not is_fast_falling or velocity.y <= fast_fall_minimum_speed:
		return 1.0  # No bonus damage
	
	# Calculate multiplier based on fall speed
	# Linear interpolation from minimum speed to terminal velocity
	var speed_ratio = (velocity.y - fast_fall_minimum_speed) / (3000.0 - fast_fall_minimum_speed)  # 3000 is fast fall terminal velocity
	speed_ratio = clamp(speed_ratio, 0.0, 1.0)
	
	# Calculate the final multiplier
	var damage_multiplier = lerp(fast_fall_damage_multiplier, max_fast_fall_damage_multiplier, speed_ratio)
	
	print("Fast fall damage! Speed: ", velocity.y, " | Multiplier: ", damage_multiplier)
	return damage_multiplier

# Head bonk mechanic functions
func check_and_handle_head_bonk() -> bool:
	# Check if we hit the ceiling while moving upward with sufficient speed
	if is_on_ceiling() and velocity.y < head_bonk_minimum_upward_velocity:
		var time_since_last_bonk = total_time - last_head_bonk_time
		
		# Only allow head bonk if enough time has passed since last one
		if time_since_last_bonk > head_bonk_cooldown:
			perform_head_bonk()
			last_head_bonk_time = total_time
			return true
	return false

func perform_head_bonk():
	print("HEAD BONK! Speed boost activated!")
	
	# Store original velocity for calculations
	var original_upward_speed = abs(velocity.y)
	
	# Stop upward velocity and add slight downward impulse (like in Minecraft)
	velocity.y = head_bonk_vertical_impulse
	
	# Apply horizontal speed boost in the direction the player is facing
	var direction = -1 if animations.flip_h else 1
	
	# Scale the boost based on how fast we were moving upward (more dramatic bonk = more speed)
	var speed_multiplier = clamp(original_upward_speed / 200.0, 0.5, 2.0)
	var actual_boost = head_bonk_speed_boost * speed_multiplier
	
	# Add the boost to current velocity (don't replace it entirely)
	# But cap it at a reasonable maximum to prevent infinite acceleration
	var new_x_velocity = velocity.x + (direction * actual_boost)
	var max_bonk_speed = head_bonk_speed_boost * 2.5  # Allow up to 2.5x the boost as max speed
	velocity.x = clamp(new_x_velocity, -max_bonk_speed, max_bonk_speed)
	
	print("Head bonk boost: ", actual_boost, " | Direction: ", direction, " | New velocity: ", velocity)
	
	# Visual feedback: briefly flash the sprite
	flash_sprite()
	
	# Emit signal for any listeners (particles, UI feedback, etc.)
	head_bonk_occurred.emit(actual_boost, direction)
	
	return

# Visual feedback for head bonk
func flash_sprite():
	if animations:
		# Create a brief flash effect
		var original_modulate = animations.modulate
		animations.modulate = Color.YELLOW  # Flash yellow briefly
		
		# Create a tween to return to normal color
		var tween = create_tween()
		tween.tween_property(animations, "modulate", original_modulate, 0.2)
		
		# Optional: Add a slight screen shake effect
		if camera:
			var original_offset = camera.offset
			var shake_strength = 3.0
			var shake_tween = create_tween()
			shake_tween.set_parallel(true)  # Allow multiple tweens
			
			# Shake in random directions
			for i in range(3):
				var random_offset = Vector2(
					randf_range(-shake_strength, shake_strength),
					randf_range(-shake_strength, shake_strength)
				)
				shake_tween.tween_property(camera, "offset", original_offset + random_offset, 0.05)
				shake_tween.tween_property(camera, "offset", original_offset, 0.05)
		
	return
