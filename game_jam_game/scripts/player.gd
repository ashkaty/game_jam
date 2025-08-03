class_name Player

extends CharacterBody2D


@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: Node2D = $AnimatedSprite2D/Sword
@onready var camera: Camera2D = $Camera2D

@onready var state_machine: Node = $state_machine
var last_flip_h: bool = false
var original_sword_position: Vector2

# Input polling system - ensures inputs are only processed once per frame
var input_just_pressed: Dictionary = {}
var input_consumed: Dictionary = {}
var input_actions: Array[String] = [
	"jump", "attack", "crouch", "dash", "move_left", "move_right", "up"
]

# Motion blur effect variables
@export var motion_blur_enabled: bool = true
@export var motion_blur_threshold: float = 300.0  # Minimum velocity to start blur
@export var motion_blur_max_velocity: float = 1500.0  # Velocity for maximum blur
@export var motion_blur_max_intensity: float = 0.4  # Maximum blur intensity (0.0 to 1.0)
@export var motion_blur_smoothing: float = 0.1  # How quickly blur changes (lower = smoother)
var current_blur_intensity: float = 0.0

# Coyote time variables
@export var coyote_time_duration: float = 0.25  # Time window for coyote jump
var coyote_timer: float = 0.0
var was_on_floor: bool = false
var coyote_available: bool = false  # Track if coyote time should be available
var jumped_off_ground: bool = false  # Track if player jumped off ground (vs walked off)

# Jump cooldown variables
@export var jump_cooldown_duration: float = 0.05  # Shorter cooldown for continuous short jumps
var jump_cooldown_timer: float = 0.0
var can_jump_again: bool = true

# Generalized input buffer system
@export var input_buffer_duration: float = 0.15  # Buffer duration for input responsiveness
@export var input_buffer_refresh_cooldown: float = 0.02  # Cooldown before buffer can be refreshed
var input_buffers: Dictionary = {}  # Stores buffered inputs with their timers
var input_buffer_hold_times: Dictionary = {}  # Stores how long inputs were held when buffered
var input_hold_start_times: Dictionary = {}  # Track when input buttons were first pressed
var last_buffer_times: Dictionary = {}  # Track when each buffer was last set

# Head bonk mechanic variables
@export var head_bonk_speed_boost: float = 300.0  # Horizontal speed added when hitting head

# Health system variables
@export var max_health: int = 3  # Player starts with 3 hearts
var current_health: int = 3
var ui_reference: Control = null  # Reference to the UI for health updates

# Invincibility frames system
@export var invincibility_duration: float = 1.5  # Duration of invincibility after taking damage
@export var invincibility_flash_rate: float = 8.0  # How fast to flash during invincibility (flashes per second)
var invincibility_timer: float = 0.0
var is_invincible: bool = false
var flash_visible: bool = true  # Track visibility state for flashing effect
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

# Action cancellation system
@export var allow_movement_cancel: bool = true  # Allow movement to cancel actions
@export var allow_jump_cancel: bool = true     # Allow jump to cancel actions  
@export var allow_dash_cancel: bool = true     # Allow dash to cancel actions
@export var action_cancel_window: float = 0.3  # Time window after action start where cancellation is allowed
@export var dash_cancel_window: float = 0.1    # Shorter cancel window for dash (more commitment)
@export var use_animation_cancel_points: bool = false  # Use specific animation frames for cancellation
var current_action_start_time: float = 0.0     # When the current action started
var current_action_cancelable: bool = false    # Whether the current action can be canceled
var current_action_type: String = ""           # Type of current action for specific cancel rules
var animation_cancel_enabled: bool = false     # Whether animation-based cancellation is currently enabled

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
	
	# Input buffer system is initialized automatically via Dictionary declarations
	# No manual initialization needed for the generalized buffer system
	
	# Add player to a group so the UI can find it
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	# Track when input buttons are first pressed for hold time calculation
	for action in input_actions:
		if event.is_action_pressed(action):
			input_hold_start_times[action] = total_time
			# print(action.capitalize(), " hold started at: ", total_time)
		elif event.is_action_released(action):
			input_hold_start_times[action] = 0.0
			# print(action.capitalize(), " hold reset - button released")
	
	# Keep calling process_input for states that haven't been converted to polling yet
	state_machine.process_input(event)

func _physics_process(delta: float) -> void:
	# Update total time for head bonk tracking
	total_time += delta
	
	# Update invincibility timer and flashing effect
	update_invincibility(delta)
	
	# Update jump cooldown timer
	if jump_cooldown_timer > 0.0:
		jump_cooldown_timer -= delta
		if jump_cooldown_timer <= 0.0:
			can_jump_again = true
			# print("Jump cooldown expired - can jump again")
	
	# Update jump buffer timer
	update_input_buffers(delta)
	
	# Update coyote time BEFORE state machine processing
	update_coyote_time(delta)
	
	state_machine.process_physics(delta)

func _process(delta: float) -> void:
	# Poll inputs first to ensure they're captured for this frame
	poll_inputs()
	
	state_machine.process_frame(delta)
	
	# Update motion blur based on velocity
	if motion_blur_enabled:
		update_motion_blur(delta)
	
	if animations.flip_h != last_flip_h:
		update_sword_position()

		last_flip_h = animations.flip_h

# Input polling system - call this every frame to capture inputs
func poll_inputs() -> void:
	# Reset consumed flags for new frame
	input_consumed.clear()
	
	# Poll all input actions and store their just_pressed state
	for action in input_actions:
		var just_pressed = Input.is_action_just_pressed(action)
		input_just_pressed[action] = just_pressed
		
		# Auto-buffer inputs when they're pressed for improved responsiveness
		if just_pressed:
			buffer_input(action)

# Public method for states to check if an action was just pressed this frame
# Returns true only once per frame, even if called multiple times
func is_action_just_pressed_once(action: String) -> bool:
	if not input_just_pressed.has(action):
		return false
	
	if input_consumed.get(action, false):
		return false  # Already consumed this frame
	
	if input_just_pressed[action]:
		input_consumed[action] = true  # Mark as consumed
		return true
	
	return false

# Public method for states to check if an action is currently pressed
func is_action_pressed_polling(action: String) -> bool:
	return Input.is_action_pressed(action)

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

func update_motion_blur(delta: float) -> void:
	"""Update motion blur effect based on player velocity"""
	if not animations:
		return
	
	# Calculate total velocity magnitude
	var velocity_magnitude = velocity.length()
	
	# Calculate target blur intensity based on velocity
	var target_intensity = 0.0
	if velocity_magnitude > motion_blur_threshold:
		var velocity_ratio = (velocity_magnitude - motion_blur_threshold) / (motion_blur_max_velocity - motion_blur_threshold)
		velocity_ratio = clamp(velocity_ratio, 0.0, 1.0)
		target_intensity = velocity_ratio * motion_blur_max_intensity
	
	# Enhance blur for fast falling (when crouching and falling fast)
	if is_action_pressed_polling("crouch") and velocity.y > 800.0:
		target_intensity = min(target_intensity * 1.5, motion_blur_max_intensity)
	
	# Smoothly interpolate current blur towards target
	current_blur_intensity = lerp(current_blur_intensity, target_intensity, motion_blur_smoothing)
	
	# Apply blur effect through material modulation and slight scale effects
	if current_blur_intensity > 0.01:
		# Create motion blur through subtle visual effects
		var blur_factor = current_blur_intensity
		
		# Subtle scale effect for speed sensation (horizontal stretch for horizontal movement)
		var horizontal_velocity_ratio = abs(velocity.x) / velocity_magnitude if velocity_magnitude > 0 else 0
		var vertical_velocity_ratio = abs(velocity.y) / velocity_magnitude if velocity_magnitude > 0 else 0
		
		var scale_x = 1.0 + (blur_factor * horizontal_velocity_ratio * 0.08)  # Horizontal stretch
		var scale_y = 1.0 + (blur_factor * vertical_velocity_ratio * 0.04)  # Slight vertical stretch
		animations.scale = Vector2(scale_x, scale_y)
		
		# Slight transparency effect for motion blur illusion, but respect invincibility flashing
		var motion_blur_alpha = 1.0 - (blur_factor * 0.15)  # Subtle transparency
		
		# If invincible, use the invincibility alpha value instead
		if is_invincible:
			motion_blur_alpha = animations.modulate.a  # Keep current invincibility alpha
		else:
			animations.modulate.a = motion_blur_alpha
		
		# Add slight color shift for high-speed effect
		var speed_tint = 1.0 - (blur_factor * 0.1)
		animations.modulate.b = speed_tint  # Slight blue reduction for warm speed tint
		
	else:
		# Reset effects when not moving fast, but respect invincibility
		animations.scale = Vector2(1.0, 1.0)
		if not is_invincible:
			animations.modulate = Color.WHITE

func trigger_motion_blur_burst(intensity: float = 0.8, duration: float = 0.2) -> void:
	"""Trigger a temporary motion blur effect for special actions like dashes or impacts"""
	if not animations or not motion_blur_enabled:
		return
	
	var burst_tween = create_tween()
	burst_tween.set_parallel(true)
	
	# Temporary intense blur effect
	var burst_scale = Vector2(1.0 + intensity * 0.15, 1.0 + intensity * 0.05)
	var burst_alpha = 1.0 - intensity * 0.3
	
	# Apply burst effect
	burst_tween.tween_property(animations, "scale", burst_scale, duration * 0.3)
	burst_tween.tween_property(animations, "modulate:a", burst_alpha, duration * 0.3)
	
	# Return to normal
	burst_tween.tween_property(animations, "scale", Vector2(1.0, 1.0), duration * 0.7)
	burst_tween.tween_property(animations, "modulate:a", 1.0, duration * 0.7)

func update_coyote_time(delta: float) -> void:
	var currently_on_floor = is_on_floor()
	
	if currently_on_floor:
		# Add motion blur effect for high-speed landings
		if not was_on_floor and abs(velocity.y) > motion_blur_threshold:
			var impact_intensity = clamp(abs(velocity.y) / 1200.0, 0.2, 0.8)
			trigger_motion_blur_burst(impact_intensity, 0.3)
		
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

# Update all input buffers - call this every physics frame
func update_input_buffers(delta: float) -> void:
	var expired_buffers = []
	
	for action in input_buffers.keys():
		input_buffers[action] -= delta
		if input_buffers[action] <= 0.0:
			expired_buffers.append(action)
			print(action.capitalize(), " buffer expired")
	
	# Remove expired buffers
	for action in expired_buffers:
		input_buffers.erase(action)
		input_buffer_hold_times.erase(action)

# Buffer any input for later execution
func buffer_input(action: String):
	# Allow refreshing the buffer if enough time has passed or if no buffer exists
	var current_time = total_time
	var last_time = last_buffer_times.get(action, 0.0)
	
	if not input_buffers.has(action) or (current_time - last_time) >= input_buffer_refresh_cooldown:
		input_buffers[action] = input_buffer_duration
		last_buffer_times[action] = current_time
		
		# Calculate how long the input has been held when buffering
		var hold_start = input_hold_start_times.get(action, current_time)
		input_buffer_hold_times[action] = current_time - hold_start
		
		# print(action.capitalize(), " buffered! Timer: ", input_buffers[action], " Hold time: ", input_buffer_hold_times[action], " at time: ", current_time)
	else:
		# print(action.capitalize(), " buffer refresh on cooldown, ignoring input")
		pass  # Do nothing when buffer refresh is on cooldown

# Check if there's a buffered input that should be executed
func has_valid_input_buffer(action: String) -> bool:
	return input_buffers.has(action) and input_buffers[action] > 0.0

# Get the hold time of a buffered input
func get_buffered_input_hold_time(action: String) -> float:
	return input_buffer_hold_times.get(action, 0.0)

# Get current hold time for any input (how long it's been held since press)
func get_current_input_hold_time(action: String) -> float:
	var hold_start = input_hold_start_times.get(action, 0.0)
	if hold_start > 0.0:
		return total_time - hold_start
	return 0.0

# Legacy helper for jump hold time (for backward compatibility)
func get_current_jump_hold_time() -> float:
	return get_current_input_hold_time("jump")

# Consume an input buffer (call this when a buffered input is executed)
func consume_input_buffer(action: String):
	var hold_time = input_buffer_hold_times.get(action, 0.0)
	
	input_buffers.erase(action)
	input_buffer_hold_times.erase(action)
	last_buffer_times.erase(action)
	
	# print(action.capitalize(), " buffer consumed! Was held for: ", hold_time, " seconds")
	return hold_time  	# Return the hold time for states to use

# Update invincibility system
func update_invincibility(delta: float) -> void:
	if is_invincible:
		invincibility_timer -= delta
		
		# Handle flashing effect during invincibility
		var flash_interval = 1.0 / invincibility_flash_rate
		var flash_time = fmod(invincibility_timer, flash_interval * 2.0)
		flash_visible = flash_time < flash_interval
		
		# Apply visibility based on flash state
		if animations:
			animations.modulate.a = 0.4 if flash_visible else 0.8
		
		# End invincibility when timer expires
		if invincibility_timer <= 0.0:
			end_invincibility()

func start_invincibility() -> void:
	"""Start invincibility frames after taking damage"""
	is_invincible = true
	invincibility_timer = invincibility_duration
	flash_visible = true
	print("Invincibility started for ", invincibility_duration, " seconds")

func end_invincibility() -> void:
	"""End invincibility frames and restore normal appearance"""
	is_invincible = false
	invincibility_timer = 0.0
	flash_visible = true
	
	# Restore normal sprite appearance
	if animations:
		animations.modulate.a = 1.0
	
	print("Invincibility ended")

func is_player_invincible() -> bool:
	"""Check if player is currently invincible"""
	return is_invincible

# Debug function to get invincibility status
func get_invincibility_status() -> Dictionary:
	"""Get detailed invincibility status for debugging"""
	return {
		"is_invincible": is_invincible,
		"time_remaining": invincibility_timer,
		"flash_visible": flash_visible,
		"total_duration": invincibility_duration
	}

# Legacy jump buffer functions for compatibility
func buffer_jump():
	buffer_input("jump")

# Check if there's a buffered jump that should be executed
func has_valid_jump_buffer() -> bool:
	return has_valid_input_buffer("jump")

# Get the hold time of the buffered jump
func get_buffered_jump_hold_time() -> float:
	return get_buffered_input_hold_time("jump")

# Consume the jump buffer (call this when a buffered jump is executed)
func consume_jump_buffer():
	return consume_input_buffer("jump")

# Convenience methods for buffering common actions
func buffer_attack():
	buffer_input("attack")

func buffer_dash():
	buffer_input("dash")

func buffer_crouch():
	buffer_input("crouch")

func has_valid_attack_buffer() -> bool:
	return has_valid_input_buffer("attack")

func has_valid_dash_buffer() -> bool:
	return has_valid_input_buffer("dash")

func has_valid_crouch_buffer() -> bool:
	return has_valid_input_buffer("crouch")

func consume_attack_buffer():
	return consume_input_buffer("attack")

func consume_dash_buffer():
	return consume_input_buffer("dash")

func consume_crouch_buffer():
	return consume_input_buffer("crouch")

# Clear all input buffers (useful for state resets or special conditions)
func clear_all_input_buffers():
	input_buffers.clear()
	input_buffer_hold_times.clear()
	last_buffer_times.clear()
	print("All input buffers cleared")

# Clear a specific input buffer
func clear_input_buffer(action: String):
	input_buffers.erase(action)
	input_buffer_hold_times.erase(action)
	last_buffer_times.erase(action)
	print(action.capitalize(), " buffer cleared")

# Debug function to see currently buffered inputs
func get_buffered_inputs() -> Array:
	return input_buffers.keys()

# Debug function to print all current buffers
func print_buffer_status():
	if input_buffers.is_empty():
		print("No inputs currently buffered")
	else:
		print("Currently buffered inputs:")
		for action in input_buffers.keys():
			print("  ", action.capitalize(), ": ", input_buffers[action], "s remaining")

# ═══════════════════════════════════════════════════════════════════════════════
# ACTION CANCELLATION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Start a new cancelable action
func start_cancelable_action(action_type: String = "default"):
	current_action_start_time = total_time
	current_action_cancelable = true
	current_action_type = action_type

# Mark current action as non-cancelable
func set_action_non_cancelable():
	current_action_cancelable = false

# Check if current action can be canceled
func can_cancel_current_action() -> bool:
	if not current_action_cancelable:
		return false
	
	# If using animation-based cancellation, check that too
	if use_animation_cancel_points and not animation_cancel_enabled:
		return false
	
	var time_since_action_start = total_time - current_action_start_time
	var cancel_window = action_cancel_window
	
	# Use shorter cancel window for dash
	if current_action_type == "dash":
		cancel_window = dash_cancel_window
	
	return time_since_action_start <= cancel_window

# Enable animation-based cancellation (called from animation events)
func enable_animation_cancel():
	animation_cancel_enabled = true

# Disable animation-based cancellation (called from animation events)  
func disable_animation_cancel():
	animation_cancel_enabled = false

# Check if player is trying to cancel with movement
func is_trying_to_cancel_with_movement() -> bool:
	if not allow_movement_cancel or not can_cancel_current_action():
		return false
	
	var input_axis = Input.get_axis("move_left", "move_right")
	return input_axis != 0.0

# Check if player is trying to cancel with jump
func is_trying_to_cancel_with_jump() -> bool:
	if not allow_jump_cancel or not can_cancel_current_action():
		return false
	
	return is_action_just_pressed_once("jump")

# Check if player is trying to cancel with dash
func is_trying_to_cancel_with_dash() -> bool:
	if not allow_dash_cancel or not can_cancel_current_action():
		return false
	
	return is_action_just_pressed_once("dash")

# Check for any cancellation input
func is_trying_to_cancel_action() -> bool:
	return is_trying_to_cancel_with_movement() or is_trying_to_cancel_with_jump() or is_trying_to_cancel_with_dash()

# Get the current action status for debugging
func get_action_status() -> Dictionary:
	return {
		"action_type": current_action_type,
		"cancelable": current_action_cancelable,
		"time_remaining": max(0.0, action_cancel_window - (total_time - current_action_start_time)),
		"animation_cancel_enabled": animation_cancel_enabled
	}

# End the current action (called when action completes or is canceled)
func end_current_action():
	current_action_cancelable = false
	animation_cancel_enabled = false
	current_action_type = ""

# ═══════════════════════════════════════════════════════════════════════════════

# Check if player can perform any type of jump (ground or coyote)
func can_jump() -> bool:
	return can_ground_jump() or can_coyote_jump()


func apply_knockback(knockback_force: Vector2):
	"""Apply knockback force to the player"""
	# Store the knockback for state machines to potentially use
	var knockback_magnitude = knockback_force.length()
	
	# Different knockback handling based on player state
	if is_on_floor():
		# Ground knockback - apply horizontal force, reduce vertical knockback
		velocity.x += knockback_force.x
		velocity.y += knockback_force.y * 0.5  # Reduce vertical knockback when grounded but allow some
	else:
		# Air knockback - apply full force for more dynamic aerial combat
		velocity += knockback_force
	
	# Clamp velocities to prevent excessive knockback but allow reasonable combat dynamics
	var max_knockback_velocity = 1200.0  # Slightly reduced for better control
	velocity.x = clamp(velocity.x, -max_knockback_velocity, max_knockback_velocity)
	velocity.y = clamp(velocity.y, -max_knockback_velocity, max_knockback_velocity)
	
	# Add visual feedback for knockback
	if knockback_magnitude > 80:  # Lowered threshold for more responsive feedback
		# Flash sprite and shake camera for significant knockback
		flash_sprite()
		var damage_equivalent = int(knockback_magnitude / 15)  # More sensitive camera shake
		shake_camera_for_damage(damage_equivalent)
		
		# Add motion blur burst effect
		var blur_intensity = clamp(knockback_magnitude / 400.0, 0.2, 0.8)
		trigger_motion_blur_burst(blur_intensity, 0.3)
	
	print("Player received knockback: ", knockback_force, " | New velocity: ", velocity, " | On floor: ", is_on_floor())

# Fast fall damage calculation
func get_fast_fall_damage_multiplier() -> float:
	# Check if player is fast falling (holding crouch) and moving downward fast enough
	var is_fast_falling = is_action_pressed_polling("crouch")
	
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
	
	# Add motion blur burst effect for head bonk
	trigger_motion_blur_burst(0.6, 0.3)
	
	# Emit signal for any listeners (particles, UI feedback, etc.)
	head_bonk_occurred.emit(actual_boost, direction)
	
	return

# Camera shake function for damage feedback
func shake_camera_for_damage(damage_amount: int):
	"""Shake the camera based on damage amount - more damage = stronger shake"""
	var game_camera = get_tree().get_first_node_in_group("game_camera")
	var player_camera = camera
	
	# Calculate shake intensity based on damage (scale from 1-5 damage to 2-15 shake strength)
	var base_shake = 5.0
	var max_shake = 45.0
	var max_damage_for_scaling = 5.0  # Updated for new damage scaling
	var damage_ratio = clamp(float(damage_amount) / max_damage_for_scaling, 0.0, 1.0)
	var shake_strength = lerp(base_shake, max_shake, damage_ratio)
	
	# Calculate duration based on damage (0.1 to 0.4 seconds)
	var base_duration = 0.1
	var max_duration = 0.4
	var shake_duration = lerp(base_duration, max_duration, damage_ratio)
	
	print("Camera shake for ", damage_amount, " damage - strength: ", shake_strength, ", duration: ", shake_duration)
	
	# Add motion blur burst effect based on damage amount
	var blur_intensity = clamp(damage_ratio * 0.5, 0.1, 0.7)
	trigger_motion_blur_burst(blur_intensity, 0.25)
	
	# Shake both cameras if they exist
	for target_camera in [game_camera, player_camera]:
		if target_camera:
			_perform_camera_shake(target_camera, shake_strength, shake_duration)

func _perform_camera_shake(target_camera: Camera2D, shake_strength: float, duration: float):
	"""Perform the actual camera shake on a specific camera"""
	var original_offset = target_camera.offset
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	var shake_steps = int(duration * 20)  # 20 steps per second for smooth shake
	var step_duration = duration / shake_steps
	
	for i in range(shake_steps):
		var progress = float(i) / shake_steps
		var falloff = 1.0 - progress  # Gradually reduce shake intensity
		var current_strength = shake_strength * falloff
		
		var random_offset = Vector2(
			randf_range(-current_strength, current_strength),
			randf_range(-current_strength, current_strength)
		)
		shake_tween.tween_property(target_camera, "offset", original_offset + random_offset, step_duration)
	
	# Return to original position at the end
	shake_tween.tween_property(target_camera, "offset", original_offset, step_duration)

# Visual feedback for head bonk
func flash_sprite():
	if animations:
		# Create a brief flash effect
		var original_modulate = animations.modulate
		animations.modulate = Color.YELLOW  # Flash yellow briefly
		
		# Create a tween to return to normal color
		var tween = create_tween()
		tween.tween_property(animations, "modulate", original_modulate, 0.2)
		
		# Use the new shake system for head bonk feedback
		shake_camera_for_damage(15)  # Moderate shake for head bonk
		
	return

# Health System Functions
func take_damage(damage_amount: int) -> void:
	"""Called when player takes damage - reduces health and updates UI"""
	# Check if player is invincible
	if is_invincible:
		print("Player is invincible! Damage ignored.")
		return
	
	if current_health <= 0:
		return  # Player is already dead
	
	current_health = max(0, current_health - damage_amount)
	print("Player took ", damage_amount, " damage! Health: ", current_health, "/", max_health)
	
	# Start invincibility frames
	start_invincibility()
	
	# Update UI to reflect health change
	update_health_ui()
	
	# Trigger camera shake for damage feedback
	shake_camera_for_damage(damage_amount * 10)  # Scale up for better feedback
	
	# Check if player died
	if current_health <= 0:
		die()

func heal(heal_amount: int) -> void:
	"""Heal the player by the specified amount"""
	if current_health >= max_health:
		return  # Already at full health
	
	current_health = min(max_health, current_health + heal_amount)
	print("Player healed for ", heal_amount, "! Health: ", current_health, "/", max_health)
	
	# Update UI to reflect health change
	update_health_ui()

func update_health_ui() -> void:
	"""Update the UI to show current health"""
	if ui_reference and ui_reference.has_method("update_hearts"):
		ui_reference.update_hearts(current_health)

func set_ui_reference(ui: Control) -> void:
	"""Set the reference to the UI for health updates"""
	ui_reference = ui
	# Initialize UI with current health
	update_health_ui()

func die() -> void:
	"""Called when player health reaches 0"""
	print("Player died! Restarting game...")
	
	# Add a brief delay before restarting to let death effects play
	await get_tree().create_timer(1.0).timeout
	
	# Restart the current scene
	get_tree().reload_current_scene()
	update_health_ui()
	
	# You can add more death effects here:
	# - Play death animation
	# - Reset player position
	# - Show game over screen
	# - Reload scene
