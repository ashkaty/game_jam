extends Control
class_name CassetteUIV2

# UI Element References
@onready var health_progress: ProgressBar = $MainContainer/LeftPanel/PlayerStats/HealthBar/HealthProgress
@onready var health_text: Label = $MainContainer/LeftPanel/PlayerStats/HealthBar/HealthText
@onready var score_value: Label = $MainContainer/LeftPanel/PlayerStats/ScoreSection/ScoreValue
@onready var level_value: Label = $MainContainer/RightPanel/StatusInfo/LevelSection/LevelValue
@onready var exp_progress: ProgressBar = $MainContainer/RightPanel/StatusInfo/ExpSection/ExpProgress
@onready var exp_text: Label = $MainContainer/RightPanel/StatusInfo/ExpSection/ExpText
@onready var close_button: Button = $Controls/CloseButton

# Button References
@onready var red_button: TextureRect = $ButtonContainer/RedButton
@onready var yellow_button: TextureRect = $ButtonContainer/YellowButton
@onready var blue_button: TextureRect = $ButtonContainer/BlueButton
@onready var green_button: TextureRect = $ButtonContainer/GreenButton

# Player reference
var player: Node = null

# UI state
var is_visible: bool = false
var slide_tween: Tween
var original_position: Vector2
var hidden_position: Vector2

# Button animation
var button_tweens: Array[Tween] = []
var button_original_positions: Array[Vector2] = []
var button_pressed_offset: float = 5.0  # How much buttons move down when pressed (reduced for smaller buttons)
var button_selected_offset: float = 8.0  # How much the selected track button stays lowered

# Track state
var track: int = 1  # Current track (1=Red, 2=Yellow, 3=Blue, 4=Green)

# Animation settings
const SLIDE_DURATION: float = 0.3
const SLIDE_EASE_TYPE = Tween.EASE_OUT
const SLIDE_TRANS_TYPE = Tween.TRANS_BACK
const BUTTON_ANIM_DURATION: float = 0.1

signal ui_toggled(visible: bool)

func _ready():
	# Store original positions for animation
	original_position = position
	hidden_position = Vector2(original_position.x, get_viewport().get_visible_rect().size.y + 50)
	
	# Wait for the next frame to ensure all nodes are properly initialized
	await get_tree().process_frame
	
	# Store button original positions
	_store_button_positions()
	
	# Set initial track state
	_update_track_display()
	
	# Start hidden
	position = hidden_position
	visible = true  # Keep visible for animations, but positioned off-screen
	is_visible = false
	
	# Connect signals
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Find player
	_find_player()
	
	# Initial update
	_update_display()

func _store_button_positions():
	button_original_positions.clear()
	var buttons = [red_button, yellow_button, blue_button, green_button]
	for button in buttons:
		if button:
			button_original_positions.append(button.position)

func _input(event):
	# Handle UI toggle
	if event.is_action_pressed("toggle_cassette_ui") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		toggle_ui()
	
	# Handle button animations when UI is visible
	if not is_visible:
		return
		
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		match key_code:
			KEY_1:
				print("Button 1 pressed - Setting track to Red")
				set_track(1)  # Red button
			KEY_2:
				set_track(2)  # Yellow button
			KEY_3:
				set_track(3)  # Blue button
			KEY_4:
				set_track(4)  # Green button

func _animate_button_press(button_index: int):
	var buttons = [red_button, yellow_button, blue_button, green_button]
	if button_index < 0 or button_index >= buttons.size():
		return
		
	var button = buttons[button_index]
	if not button:
		return
	
	# Stop any existing tween for this button
	if button_index < button_tweens.size() and button_tweens[button_index]:
		button_tweens[button_index].kill()
	
	# Ensure we have enough tween slots
	while button_tweens.size() <= button_index:
		button_tweens.append(null)
	
	# Create new tween
	button_tweens[button_index] = create_tween()
	var tween = button_tweens[button_index]
	
	# Get original position and calculate target positions
	var original_pos = button_original_positions[button_index]
	var pressed_pos = Vector2(original_pos.x, original_pos.y + button_pressed_offset)
	
	# Determine final position based on track state
	var track_button_index = track - 1  # Convert track (1-4) to index (0-3)
	var final_pos = original_pos
	if button_index == track_button_index:
		final_pos = Vector2(original_pos.x, original_pos.y + button_selected_offset)
	
	# Animate button press (down then to final position)
	tween.tween_property(button, "position", pressed_pos, BUTTON_ANIM_DURATION)
	tween.tween_property(button, "position", final_pos, BUTTON_ANIM_DURATION)

func set_track(new_track: int):
	"""Set the current track and update button positions"""
	if new_track < 0 or new_track > 4:
		return
	
	if track != new_track:
		track = new_track
		print("CassetteUIV2: Track set to ", track)
		
		# Animate the button press for the selected track (if any)
		if track > 0:
			_animate_button_press(track - 1)
		
		# Update all button positions to reflect new track state
		_update_track_display()

func _update_track_display():
	"""Update button positions based on current track state"""
	var buttons = [red_button, yellow_button, blue_button, green_button]
	var track_button_index = track - 1  # Convert track (1-4) to index (0-3), or -1 for no track
	
	for i in range(buttons.size()):
		var button = buttons[i]
		if not button or i >= button_original_positions.size():
			continue
		
		var original_pos = button_original_positions[i]
		var target_pos = original_pos
		
		# Lower the button if it's the selected track
		if track > 0 and i == track_button_index:
			target_pos = Vector2(original_pos.x, original_pos.y + button_selected_offset)
		
		# Smoothly move to target position
		var tween = create_tween()
		tween.tween_property(button, "position", target_pos, BUTTON_ANIM_DURATION * 2)

func _find_player():
	# Try multiple methods to find the player
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node:
			player = game_node.get_node_or_null("Player")
	
	if not player:
		# Search for Player node in the scene tree
		var root = get_tree().current_scene
		player = _search_for_player(root)
	
	if player:
		print("CassetteUIV2: Found player - ", player.name)
	else:
		print("CassetteUIV2: Player not found")

func _search_for_player(node: Node) -> Node:
	      if node.name == "Player":
		return node
	
	for child in node.get_children():
		var result = _search_for_player(child)
		if result:
			return result
	
	return null

func toggle_ui():
	"""Toggle the visibility of the cassette UI with smooth animation"""
	if is_visible:
		hide_ui()
	else:
		show_ui()

func show_ui():
	"""Show the cassette UI with slide-in animation"""
	if is_visible:
		return
		
	is_visible = true
	_update_display()
	
	# Create slide-in animation
	if slide_tween:
		slide_tween.kill()
	
	slide_tween = create_tween()
	slide_tween.set_ease(SLIDE_EASE_TYPE)
	slide_tween.set_trans(SLIDE_TRANS_TYPE)
	slide_tween.tween_property(self, "position", original_position, SLIDE_DURATION)
	
	ui_toggled.emit(true)
	print("CassetteUIV2: UI shown")

func hide_ui():
	"""Hide the cassette UI with slide-out animation"""
	if not is_visible:
		return
		
	is_visible = false
	
	# Create slide-out animation
	if slide_tween:
		slide_tween.kill()
	
	slide_tween = create_tween()
	slide_tween.set_ease(SLIDE_EASE_TYPE)
	slide_tween.set_trans(SLIDE_TRANS_TYPE)
	slide_tween.tween_property(self, "position", hidden_position, SLIDE_DURATION)
	
	ui_toggled.emit(false)
	print("CassetteUIV2: UI hidden")

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_ui()

func _update_display():
	"""Update all displayed information"""
	if not is_visible:
		return
		
	var health = 100
	var max_health = 100
	var score = 0
	var level = 1
	var experience = 0
	var exp_needed = 100
	
	# Get data from player if available
	if player:
		if player.has_method("get_health"):
			health = player.get_health()
		if player.has_method("get_max_health"):
			max_health = player.get_max_health()
		if player.has_method("get_score"):
			score = player.get_score()
		if player.has_method("get_level"):
			level = player.get_level()
		if player.has_method("get_experience"):
			experience = player.get_experience()
			exp_needed = level * 100  # Simple calculation
	
	# Update health
	health_progress.max_value = max_health
	health_progress.value = health
	health_text.text = "%d/%d" % [health, max_health]
	
	# Update health bar color based on health percentage
	var health_percent = float(health) / float(max_health)
	if health_percent > 0.6:
		health_progress.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_progress.modulate = Color.YELLOW
	else:
		health_progress.modulate = Color.RED
	
	# Update score
	score_value.text = str(score)
	
	# Update level
	level_value.text = str(level)
	
	# Update experience
	exp_progress.max_value = exp_needed
	exp_progress.value = experience
	exp_text.text = "%d/%d" % [experience, exp_needed]

func _process(delta):
	"""Continuous updates when visible"""
	if is_visible:
		_update_display()

# Public methods for external control
func set_player_reference(player_node: Node):
	"""Set the player reference manually"""
	player = player_node
	print("CassetteUIV2: Player reference set to ", player_node.name if player_node else "null")

func force_update():
	"""Force an immediate update of the display"""
	_update_display()

func is_ui_visible() -> bool:
	"""Check if the UI is currently visible"""
	return is_visible

func get_track() -> int:
	"""Get the current track number (1-4)"""
	return track

func get_track_name() -> String:
	"""Get the current track name"""
	match track:
		1: return "Red"
		2: return "Yellow" 
		3: return "Blue"
		4: return "Green"
		_: return "Unknown"

# Animation event handlers
func _on_slide_animation_finished():
	"""Called when slide animation completes"""
	if not is_visible:
		# UI is now fully hidden
		pass
	else:
		# UI is now fully shown
		pass

# Public methods for external scripts to control button animations
func animate_red_button():
	set_track(1)

func animate_yellow_button():
	set_track(2)

func animate_blue_button():
	set_track(3)

func animate_green_button():
	set_track(4)

# Direct button press animations (for external use)
func press_red_button():
	set_track(1)  # Use track system to ensure only one button is down

func press_yellow_button():
	set_track(2)  # Use track system to ensure only one button is down

func press_blue_button():
	set_track(3)  # Use track system to ensure only one button is down

func press_green_button():
	set_track(4)  # Use track system to ensure only one button is down

func clear_all_buttons():
	"""Clear all button states - return all buttons to original positions"""
	# Reset track to 0 (no track selected) and update display
	track = 0
	_update_track_display()
