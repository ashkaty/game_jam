extends Control
class_name CassetteButtonlessUI

# Button References - adjusted to match actual scene structure
@onready var background: Sprite2D = $Background
@onready var red_button: Sprite2D = $RedButton
@onready var yellow_button: Sprite2D = $YellowButton
@onready var blue_button: Sprite2D = $BlueButton
@onready var green_button: Sprite2D = $GreenButton

# UI References
@onready var timer_label: Label = $TimerContainer/VBoxContainer/TimerLabel
@onready var timer_progress_bar: ProgressBar = $ProgressBar

# Audio Reference
@onready var button_click_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Player reference
var player: Node = null

# UI state
var is_visible: bool = true
var slide_tween: Tween
var original_position: Vector2
var hidden_position: Vector2

# Button animation
var button_tweens: Array[Tween] = []
var button_original_positions: Array[Vector2] = []
var button_pressed_offset: float = 50.0  # How much buttons move down when pressed
var red_button_drop_offset: float = 50.0  # How far red button drops when key 1 is pressed

# Button state variables
var red_button_dropped: bool = false
var yellow_button_dropped: bool = false
var blue_button_dropped: bool = false
var green_button_dropped: bool = false

# Button original positions
var red_button_original_position: Vector2
var yellow_button_original_position: Vector2
var blue_button_original_position: Vector2
var green_button_original_position: Vector2

# Animation settings
const SLIDE_DURATION: float = 0.3
const SLIDE_EASE_TYPE = Tween.EASE_OUT
const SLIDE_TRANS_TYPE = Tween.TRANS_BACK
const BUTTON_ANIM_DURATION: float = 0.3

# Timer variables
var countdown_time: float = 60.0  # 1 minute in seconds
var time_remaining: float = 60.0
var is_timer_running: bool = false

# Multi-track timer system
var track_timers: Dictionary = {}  # Stores time remaining for each track
var current_track: int = 1  # Currently active track (1-4)
var default_track_time: float = 60.0  # Default time for new tracks

signal ui_toggled(visible: bool)
signal timer_finished()
signal track_timer_finished(track_number: int)

func _ready():
	# Store original positions for animation
	original_position = position
	hidden_position = Vector2(original_position.x, get_viewport().get_visible_rect().size.y + 50)
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Store button original positions
	_store_button_positions()
	
	# Store red button's original position specifically
	if red_button:
		red_button_original_position = red_button.position
	if yellow_button:
		yellow_button_original_position = yellow_button.position
	if blue_button:
		blue_button_original_position = blue_button.position
	if green_button:
		green_button_original_position = green_button.position
	
	# Start hidden
	position = hidden_position
	visible = true  # Keep visible for animations, but positioned off-screen
	is_visible = true
	
	# Find player
	_find_player()
	
	# Initialize progress bar settings
	if timer_progress_bar:
		timer_progress_bar.max_value = 100.0
		timer_progress_bar.min_value = 0.0
		timer_progress_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
		timer_progress_bar.value = 0.0  # Start at 0 (no progress yet)
		print("Progress bar initialized: max=", timer_progress_bar.max_value, ", min=", timer_progress_bar.min_value)
	
	# Initialize track timers
	_initialize_track_timers()
	
	# Start the countdown timer for track 1
	switch_to_track(1)
	
	# Drop red button by default when game starts
	_drop_red_button()

func _store_button_positions():
	button_original_positions.clear()
	var buttons = [red_button, yellow_button, blue_button, green_button]
	for button in buttons:
		if button:
			button_original_positions.append(button.position)

func _input(event):
	# Handle UI toggle
	if event.is_action_pressed("toggle_cassette_ui") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		toggle_visibility()
		#print("UI toggled, is_visible: ", is_visible)
	
	# Handle button animations when UI is visible
	#if not is_visible:
		#if event is InputEventKey and event.pressed and event.keycode == KEY_1:
	#		print("Key 1 pressed but UI is not visible (is_visible: ", is_visible, ")")
	#	return
		
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		#print("Input received, key: ", key_code, ", UI visible: ", is_visible)
		match key_code:
			KEY_1:
				#print("Key 1 pressed - Switching to track 1 (Red)")
				if button_click_audio:
					button_click_audio.play()
				switch_to_track(1)
				_set_only_button_dropped("red")
			KEY_2:
				#print("Key 2 pressed - Switching to track 2 (Yellow)")
				if button_click_audio:
					button_click_audio.play()
				switch_to_track(2)
				_set_only_button_dropped("yellow")
			KEY_3:
				#print("Key 3 pressed - Switching to track 3 (Blue)")
				if button_click_audio:
					button_click_audio.play()
				switch_to_track(3)
				_set_only_button_dropped("blue")
			KEY_4:
				#print("Key 4 pressed - Switching to track 4 (Green)")
				if button_click_audio:
					button_click_audio.play()
				switch_to_track(4)
				_set_only_button_dropped("green")

func _animate_button_press(button_index: int):
	var buttons = [red_button, yellow_button, blue_button, green_button]
	if button_index < 0 or button_index >= buttons.size():
		return
		
	var button = buttons[button_index]
	if not button:
		return
	
	# Don't animate red button with normal press if it's already dropped
	if button == red_button and red_button_dropped:
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
	
	# Get original position
	var original_pos = button_original_positions[button_index]
	var pressed_pos = Vector2(original_pos.x, original_pos.y + button_pressed_offset)
	
	# Animate button press (down then back up)
	tween.tween_property(button, "position", pressed_pos, BUTTON_ANIM_DURATION)
	tween.tween_property(button, "position", original_pos, BUTTON_ANIM_DURATION)

func _drop_red_button():
	"""Drop the red button 200 pixels down"""
	print("_drop_red_button called, red_button exists: ", red_button != null, ", already dropped: ", red_button_dropped)
	if not red_button or red_button_dropped:
		return
	
	print("Dropping red button from position: ", red_button.position, " to: ", Vector2(red_button_original_position.x, red_button_original_position.y + red_button_drop_offset))
	red_button_dropped = true
	var target_position = Vector2(red_button_original_position.x, red_button_original_position.y + red_button_drop_offset)
	
	# Create smooth drop animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(red_button, "position", target_position, BUTTON_ANIM_DURATION * 2)

func _return_red_button():
	"""Return the red button to its original position"""
	if not red_button or not red_button_dropped:
		return
	
	red_button_dropped = false
	
	# Create smooth return animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(red_button, "position", red_button_original_position, BUTTON_ANIM_DURATION)

func _drop_yellow_button():
	"""Drop the yellow button down"""
	print("_drop_yellow_button called, yellow_button exists: ", yellow_button != null, ", already dropped: ", yellow_button_dropped)
	if not yellow_button or yellow_button_dropped:
		return
	
	print("Dropping yellow button from position: ", yellow_button.position, " to: ", Vector2(yellow_button_original_position.x, yellow_button_original_position.y + button_pressed_offset))
	yellow_button_dropped = true
	var target_position = Vector2(yellow_button_original_position.x, yellow_button_original_position.y + button_pressed_offset)
	
	# Create smooth drop animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(yellow_button, "position", target_position, BUTTON_ANIM_DURATION * 2)

func _return_yellow_button():
	"""Return the yellow button to its original position"""
	if not yellow_button or not yellow_button_dropped:
		return
	
	yellow_button_dropped = false
	
	# Create smooth return animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(yellow_button, "position", yellow_button_original_position, BUTTON_ANIM_DURATION)

func _drop_blue_button():
	"""Drop the blue button down"""
	print("_drop_blue_button called, blue_button exists: ", blue_button != null, ", already dropped: ", blue_button_dropped)
	if not blue_button or blue_button_dropped:
		return
	
	print("Dropping blue button from position: ", blue_button.position, " to: ", Vector2(blue_button_original_position.x, blue_button_original_position.y + button_pressed_offset))
	blue_button_dropped = true
	var target_position = Vector2(blue_button_original_position.x, blue_button_original_position.y + button_pressed_offset)
	
	# Create smooth drop animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(blue_button, "position", target_position, BUTTON_ANIM_DURATION * 2)

func _return_blue_button():
	"""Return the blue button to its original position"""
	if not blue_button or not blue_button_dropped:
		return
	
	blue_button_dropped = false
	
	# Create smooth return animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(blue_button, "position", blue_button_original_position, BUTTON_ANIM_DURATION)

func _drop_green_button():
	"""Drop the green button down"""
	print("_drop_green_button called, green_button exists: ", green_button != null, ", already dropped: ", green_button_dropped)
	if not green_button or green_button_dropped:
		return
	
	print("Dropping green button from position: ", green_button.position, " to: ", Vector2(green_button_original_position.x, green_button_original_position.y + button_pressed_offset))
	green_button_dropped = true
	var target_position = Vector2(green_button_original_position.x, green_button_original_position.y + button_pressed_offset)
	
	# Create smooth drop animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(green_button, "position", target_position, BUTTON_ANIM_DURATION * 2)

func _return_green_button():
	"""Return the green button to its original position"""
	if not green_button or not green_button_dropped:
		return
	
	green_button_dropped = false
	
	# Create smooth return animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(green_button, "position", green_button_original_position, BUTTON_ANIM_DURATION)

func _return_all_other_buttons(except_button: String):
	"""Return all buttons to original position except the specified one"""
	if except_button != "red":
		_return_red_button()
	if except_button != "yellow":
		_return_yellow_button()
	if except_button != "blue":
		_return_blue_button()
	if except_button != "green":
		_return_green_button()

func _set_only_button_dropped(button_name: String):
	"""Ensure only one button is dropped at a time"""
	# First, return all buttons to their original positions
	_return_all_buttons()
	
	# Then drop only the specified button
	match button_name:
		"red":
			_drop_red_button()
		"yellow":
			_drop_yellow_button()
		"blue":
			_drop_blue_button()
		"green":
			_drop_green_button()

func _return_all_buttons():
	"""Return all buttons to their original positions"""
	_return_red_button()
	_return_yellow_button()
	_return_blue_button()
	_return_green_button()

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
		print("CassetteButtonlessUI: Found player - ", player.name)
	else:
		print("CassetteButtonlessUI: Player not found")

func _search_for_player(node: Node) -> Node:
	if node.name == "Player" or node is Player:
		return node
	
	for child in node.get_children():
		var result = _search_for_player(child)
		if result:
			return result
	
	return null

func toggle_visibility():
	is_visible = !is_visible
	_animate_slide()
	ui_toggled.emit(is_visible)

func show_ui():
	if not is_visible:
		is_visible = true
		_animate_slide()
		ui_toggled.emit(is_visible)

func hide_ui():
	if is_visible:
		is_visible = false
		_animate_slide()
		ui_toggled.emit(is_visible)

func _animate_slide():
	# Kill existing tween
	if slide_tween:
		slide_tween.kill()
	
	slide_tween = create_tween()
	slide_tween.set_ease(SLIDE_EASE_TYPE)
	slide_tween.set_trans(SLIDE_TRANS_TYPE)
	
	var target_position = original_position if is_visible else hidden_position
	slide_tween.tween_property(self, "position", target_position, SLIDE_DURATION)

# Simplified display update since this is just button UI
func _update_display():
	# This version is just for button animations, no stats display
	pass

# Timer functions
func start_timer():
	"""Start the countdown timer for current track"""
	if timer_label:
		# Use the current track's time remaining
		is_timer_running = true
		_update_timer_display()
		_update_progress_bar()
		print("Timer started for track ", current_track, " - time remaining: ", time_remaining, " seconds")
	else:
		print("Error: TimerLabel not found! Cannot start timer.")

func _process(delta):
	"""Update timer each frame"""
	if is_timer_running:
		time_remaining -= delta
		_update_timer_display()
		_update_progress_bar()
		
		# Check if current track timer has finished
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_update_timer_display()
			_update_progress_bar()
			
			# Save the completed track time
			track_timers[current_track] = 0.0
			
			print("Track ", current_track, " timer finished!")
			timer_finished.emit()
			track_timer_finished.emit(current_track)
			
			# Stop timer for this track but don't auto-switch
			# User needs to manually switch to continue with other tracks

func _update_timer_display():
	"""Update the timer label with current time"""
	if not timer_label:
		print("Warning: TimerLabel is null, cannot update display")
		return
	
	# Convert to minutes and seconds
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	
	# Format as MM:SS
	var time_text = "%02d:%02d" % [minutes, seconds]
	timer_label.text = time_text
	
	# Debug output every 10 seconds
	if int(time_remaining) % 10 == 0 and time_remaining != 0:
		print("Timer: ", time_text)

func _update_progress_bar():
	"""Update the progress bar with current time remaining"""
	if not timer_progress_bar:
		print("Warning: ProgressBar is null, cannot update display")
		return
	
	# Ensure progress bar is configured correctly
	timer_progress_bar.max_value = 100.0
	timer_progress_bar.min_value = 0.0
	timer_progress_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	
	# Calculate progress percentage (elapsed time / total time * 100)
	# This will grow from 0 to 100 as time progresses
	var elapsed_time = default_track_time - time_remaining
	var progress_percentage = (elapsed_time / default_track_time) * 100.0
	progress_percentage = max(0.0, min(100.0, progress_percentage))  # Clamp between 0-100
	
	timer_progress_bar.value = progress_percentage
	
	# Debug output to verify progress bar is updating
	if int(time_remaining) % 5 == 0:  # Debug every 5 seconds
		print("Progress bar updated: ", progress_percentage, "% - Elapsed: ", elapsed_time, "/", default_track_time, " - Track ", current_track)
		print("Progress bar max_value: ", timer_progress_bar.max_value, ", current value: ", timer_progress_bar.value)

func get_time_remaining() -> float:
	"""Get the remaining time in seconds"""
	return time_remaining

func is_timer_active() -> bool:
	"""Check if the timer is currently running"""
	return is_timer_running

func stop_timer():
	"""Stop the timer"""
	is_timer_running = false

func reset_timer():
	"""Reset the current track timer to default track time"""
	time_remaining = default_track_time
	track_timers[current_track] = default_track_time
	_update_timer_display()
	_update_progress_bar()
	print("Reset track ", current_track, " timer to: ", default_track_time)

func set_countdown_time(new_time: float):
	"""Set a new countdown time"""
	countdown_time = new_time
	if not is_timer_running:
		time_remaining = countdown_time
		_update_timer_display()
		_update_progress_bar()

# Multi-track timer system functions
func _initialize_track_timers():
	"""Initialize all track timers with default time"""
	for i in range(1, 5):  # Tracks 1-4
		track_timers[i] = default_track_time
	print("Track timers initialized: ", track_timers)

func switch_to_track(track_number: int):
	"""Switch to a different track, saving current progress and loading new track's progress"""
	if track_number < 1 or track_number > 4:
		print("Invalid track number: ", track_number)
		return
	
	# Save current track's timer state
	if current_track >= 1 and current_track <= 4:
		track_timers[current_track] = time_remaining
		print("Saved track ", current_track, " time: ", track_timers[current_track])
	
	# Switch to new track
	var old_track = current_track
	current_track = track_number
	
	# Load new track's timer state
	time_remaining = track_timers[current_track]
	print("Switched from track ", old_track, " to track ", current_track, " - loaded time: ", time_remaining)
	
	# Update display
	_update_timer_display()
	_update_progress_bar()
	
	# Start timer if it wasn't running
	if not is_timer_running and time_remaining > 0:
		is_timer_running = true
		print("Started timer for track ", current_track)

func get_current_track() -> int:
	"""Get the currently active track number"""
	return current_track

func get_track_time_remaining(track_number: int) -> float:
	"""Get the time remaining for a specific track"""
	if track_number >= 1 and track_number <= 4:
		if track_number == current_track:
			return time_remaining
		else:
			return track_timers[track_number]
	return 0.0

func set_track_time(track_number: int, new_time: float):
	"""Set the time for a specific track"""
	if track_number >= 1 and track_number <= 4:
		if track_number == current_track:
			time_remaining = new_time
			_update_timer_display()
			_update_progress_bar()
		else:
			track_timers[track_number] = new_time
		print("Set track ", track_number, " time to: ", new_time)

func reset_track_timer(track_number: int):
	"""Reset a specific track timer to default time"""
	if track_number >= 1 and track_number <= 4:
		if track_number == current_track:
			time_remaining = default_track_time
			_update_timer_display()
			_update_progress_bar()
		else:
			track_timers[track_number] = default_track_time
		print("Reset track ", track_number, " timer to: ", default_track_time)

func reset_all_track_timers():
	"""Reset all track timers to default time"""
	for i in range(1, 5):
		track_timers[i] = default_track_time
	if current_track >= 1 and current_track <= 4:
		time_remaining = default_track_time
		_update_timer_display()
		_update_progress_bar()
	print("Reset all track timers to: ", default_track_time)

func get_all_track_times() -> Dictionary:
	"""Get a dictionary of all track times"""
	var all_times = track_timers.duplicate()
	all_times[current_track] = time_remaining  # Update current track with live time
	return all_times

# Public methods for external scripts to control button animations
func animate_red_button():
	if button_click_audio:
		button_click_audio.play()
	switch_to_track(1)
	_set_only_button_dropped("red")

func animate_yellow_button():
	if button_click_audio:
		button_click_audio.play()
	switch_to_track(2)
	_set_only_button_dropped("yellow")

func animate_blue_button():
	if button_click_audio:
		button_click_audio.play()
	switch_to_track(3)
	_set_only_button_dropped("blue")

func animate_green_button():
	if button_click_audio:
		button_click_audio.play()
	switch_to_track(4)
	_set_only_button_dropped("green")

# Public methods for external control
func set_player_reference(player_node: Node):
	"""Set the player reference manually"""
	player = player_node
	print("CassetteButtonlessUI: Player reference set to ", player_node.name if player_node else "null")

func is_ui_visible() -> bool:
	"""Check if the UI is currently visible"""
	return is_visible

func is_red_button_dropped() -> bool:
	"""Check if red button is currently dropped"""
	return red_button_dropped

func is_yellow_button_dropped() -> bool:
	"""Check if yellow button is currently dropped"""
	return yellow_button_dropped

func is_blue_button_dropped() -> bool:
	"""Check if blue button is currently dropped"""
	return blue_button_dropped

func is_green_button_dropped() -> bool:
	"""Check if green button is currently dropped"""
	return green_button_dropped

func force_drop_red_button():
	"""Force drop red button (external API)"""
	_drop_red_button()

func force_return_red_button():
	"""Force return red button (external API)"""
	_return_red_button()

func force_drop_yellow_button():
	"""Force drop yellow button (external API)"""
	_drop_yellow_button()

func force_return_yellow_button():
	"""Force return yellow button (external API)"""
	_return_yellow_button()

func force_drop_blue_button():
	"""Force drop blue button (external API)"""
	_drop_blue_button()

func force_return_blue_button():
	"""Force return blue button (external API)"""
	_return_blue_button()

func force_drop_green_button():
	"""Force drop green button (external API)"""
	_drop_green_button()

func force_return_green_button():
	"""Force return green button (external API)"""
	_return_green_button()

func clear_all_buttons():
	"""Clear all button states - return all to original positions"""
	_return_all_buttons()
