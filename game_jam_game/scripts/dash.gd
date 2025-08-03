extends State

@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var land_state: State
@export var jump_state: State
@export var air_attack_state: State
@export var crouch_state: State

# ---- Dash Tunables --------------------------------------------------------
@export var dash_speed: float = 5000.0  # Speed of the dash
@export var dash_duration: float = 0.1  # How long the dash lasts
@export var dash_cooldown: float = 1.0  # Cooldown between dashes
@export var air_dash_enabled: bool = true  # Whether dashing is allowed in air
@export var dash_gravity_scale: float = 0.1  # Reduced gravity during dash (near zero for horizontal dash)
@export var dash_override_velocity: bool = true  # Whether dash completely overrides velocity or adds to it
@export var collision_avoidance_enabled: bool = true  # Whether to enable collision avoidance
@export var avoidance_check_distance: float = 64.0  # How far ahead to check for collisions
@export var avoidance_offset: float = 32.0  # How much to move up/down to avoid collision
@export var max_avoidance_attempts: int = 3  # Maximum number of avoidance attempts
@export var animation_name: String = "nauruto_run"

# Dash state tracking
var dash_timer: float = 0.0
var dash_direction: int = 1  # 1 for right, -1 for left
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true
var dash_slowed_by_crouch: bool = false  # Track if dash was slowed by crouch input

# Original values to restore after dash
var original_sword_position: Vector2

func enter() -> void:
	super()
	print("Entering dash state")
	
	# Start cancelable action tracking (dash has shorter cancel window)
	parent.start_cancelable_action("dash")
	
	# Trigger motion blur for dash
	if parent.has_method("trigger_motion_blur_burst"):
		parent.trigger_motion_blur_burst(0.6, 0.15)
	
        # Set dash direction based on which way player is facing
        dash_direction = -1 if parent.is_facing_left() else 1
	
	# Reset dash timer and crouch slowdown flag
	dash_timer = dash_duration
	dash_slowed_by_crouch = false
	
	# Set dash velocity
	if dash_override_velocity:
		parent.velocity.x = dash_direction * dash_speed
		parent.velocity.y = 0  # Stop vertical movement during dash
	else:
		parent.velocity.x += dash_direction * dash_speed
	
	# Store original sword position 
	if parent.sword:
		original_sword_position = parent.sword.position
	
        # Start cooldown
        can_dash = false
        dash_cooldown_timer = dash_cooldown

func exit() -> void:
	print("Exiting dash state")
	# Reset sword position when exiting dash
	if parent.sword:
		parent.sword.position = original_sword_position
		parent.update_sword_position()  # Let the player handle direction

func process_frame(delta: float) -> State:
	# Update dash timer
	dash_timer -= delta
	
	# Update cooldown timer
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true
			print("Dash cooldown expired - can dash again")
	
	return null

func process_input(_event: InputEvent) -> State:
	# Check for action cancellation first (jump can cancel dash)
	if parent.is_trying_to_cancel_with_jump() and parent.can_jump():
		parent.end_current_action()
		return jump_state
	
	# Allow movement input to cancel dash early and transition to move/idle
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis == 0:
		# No movement input - transition to appropriate state
		if parent.is_on_floor():
			return idle_state
		else:
			return fall_state
	elif (input_axis > 0 and dash_direction < 0) or (input_axis < 0 and dash_direction > 0):
		# Input is in opposite direction of dash - cancel dash and start moving
		if parent.is_on_floor():
			return move_state
		else:
			return fall_state
	
	# Allow attack during dash
	if parent.is_action_just_pressed_once('attack'):
		return air_attack_state
	
	# Handle crouch input during dash - immediately slow down and transition to crouch
	if parent.is_action_just_pressed_once('crouch'):
		# Reduce velocity significantly to simulate immediate slowdown
		parent.velocity.x *= 0.3  # Reduce horizontal speed to 30% of current
		dash_slowed_by_crouch = true  # Mark that dash was slowed
		print("Dash slowed by crouch input!")
		# Transition to crouch state if on floor, otherwise continue dash but slower
		if parent.is_on_floor():
			return crouch_state
		# If in air, we'll let the dash continue but at reduced speed
	
	# Can't trigger another dash while dashing
	# Other inputs are generally ignored during dash
	return null

func process_physics(delta: float) -> State:
	# Apply very reduced gravity during dash for more horizontal movement
	parent.velocity.y += gravity * dash_gravity_scale * delta
	
	# Maintain dash speed (don't let it decay naturally), unless slowed by crouch
	if dash_timer > 0.0 and not dash_slowed_by_crouch:
		parent.velocity.x = dash_direction * dash_speed
	elif dash_slowed_by_crouch:
		# If slowed by crouch, let natural deceleration take over but apply some friction
		var current_speed = abs(parent.velocity.x)
		var deceleration_rate = 2000.0  # Adjust this for how quickly it should slow down
		var new_speed = move_toward(current_speed, 0.0, deceleration_rate * delta)
		parent.velocity.x = sign(parent.velocity.x) * new_speed
	
	parent.move_and_slide()
	
	# Perform collision avoidance if enabled
	if collision_avoidance_enabled and dash_timer > 0.0:
		check_and_avoid_collision()
	
	# Check if dash duration is over
	if dash_timer <= 0.0:
		# Dash is over, transition to appropriate state based on current conditions
		if parent.is_on_floor():
			# Check if player is holding movement input
			var input_axis = Input.get_axis("move_left", "move_right")
			if input_axis != 0.0:
				return move_state
			else:
				return idle_state
		else:
			# In air, go to fall state
			return fall_state
	
	# Check for landing during dash
	if parent.is_on_floor() and parent.velocity.y >= 0:
		# Let dash complete, but we can transition faster
		return null
	
	return null

# Static method to check if dash is available
static func can_perform_dash(state_node: Node) -> bool:
	if state_node.has_method("is_dash_available"):
		return state_node.is_dash_available()
	return false

# Method to check if dash is currently available
func is_dash_available() -> bool:
	return can_dash

# Method to be called by other states to update cooldown
func update_cooldown(delta: float):
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true

# Check for upcoming collisions and automatically avoid them
func check_and_avoid_collision():
	if not parent:
		return
	
	# Get the player's collision shape
	var collision_shape = parent.get_node("CollisionShape2D") as CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	# Get player bounds
	var shape_rect = collision_shape.shape.get_rect()
	var player_half_height = (shape_rect.size.y * collision_shape.scale.y) / 2
	var player_half_width = (shape_rect.size.x * collision_shape.scale.x) / 2
	
	var space_state = parent.get_world_2d().direct_space_state
	var start_pos = parent.global_position
	
	# Check multiple points ahead for collision (top, center, bottom of player)
	var check_points = [
		start_pos + Vector2(0, -player_half_height * 0.8),  # Near top
		start_pos,  # Center
		start_pos + Vector2(0, player_half_height * 0.8)   # Near bottom
	]
	
	var collision_detected = false
	var closest_collision_distance = INF
	
	for point in check_points:
		var end_pos = point + Vector2(dash_direction * avoidance_check_distance, 0)
		var query = PhysicsRayQueryParameters2D.create(point, end_pos)
		query.collision_mask = 1
		query.exclude = [parent]
		
		var result = space_state.intersect_ray(query)
		if result:
			var distance = point.distance_to(result.position)
			if distance < closest_collision_distance:
				closest_collision_distance = distance
				collision_detected = true
	
	if collision_detected and closest_collision_distance <= avoidance_check_distance:
		print("Collision detected ahead at distance: ", closest_collision_distance)
		
		# Determine best avoidance direction based on surrounding space
		var best_direction = find_best_avoidance_direction()
		if best_direction != Vector2.ZERO:
			parent.global_position += best_direction
			print("Avoided collision by moving: ", best_direction)
		else:
			print("Could not find safe avoidance direction")

# Find the best direction to avoid collision
func find_best_avoidance_direction() -> Vector2:
	var space_state = parent.get_world_2d().direct_space_state
	var current_pos = parent.global_position
	
	# Test multiple avoidance directions (up, down, slight diagonals)
	var test_directions = [
		Vector2(0, -avoidance_offset),           # Up
		Vector2(0, avoidance_offset),            # Down
		Vector2(0, -avoidance_offset * 0.5),     # Slight up
		Vector2(0, avoidance_offset * 0.5),      # Slight down
		Vector2(dash_direction * 16, -avoidance_offset), # Diagonal up-forward
		Vector2(dash_direction * 16, avoidance_offset)   # Diagonal down-forward
	]
	
	for direction in test_directions:
		var test_pos = current_pos + direction
		
		# Check if this position is safe
		if is_position_safe(test_pos):
			return direction
	
	return Vector2.ZERO

# Check if a position is safe (no collisions)
func is_position_safe(test_position: Vector2) -> bool:
	var space_state = parent.get_world_2d().direct_space_state
	
	# Test the position itself
	var query = PhysicsPointQueryParameters2D.new()
	query.position = test_position
	query.collision_mask = 1
	query.exclude = [parent]
	
	var results = space_state.intersect_point(query)
	if not results.is_empty():
		return false
	
	# Test the path to that position
	var path_query = PhysicsRayQueryParameters2D.create(parent.global_position, test_position)
	path_query.collision_mask = 1
	path_query.exclude = [parent]
	
	var path_result = space_state.intersect_ray(path_query)
	if path_result:
		return false
	
	# Test that we can continue dashing from that position
	var dash_continue_end = test_position + Vector2(dash_direction * avoidance_check_distance * 0.5, 0)
	var dash_query = PhysicsRayQueryParameters2D.create(test_position, dash_continue_end)
	dash_query.collision_mask = 1
	dash_query.exclude = [parent]
	
	var dash_result = space_state.intersect_ray(dash_query)
	# Allow some collision in the distance, but prefer paths with more clearance
	return not dash_result or test_position.distance_to(dash_result.position) > avoidance_check_distance * 0.3
