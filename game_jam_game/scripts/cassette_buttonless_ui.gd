extends Control
class_name CassetteButtonlessUI

# Button References - adjusted to match actual scene structure
@onready var background: Sprite2D = $Background
@onready var red_button: Sprite2D = $Background/RedButton
@onready var yellow_button: Sprite2D = $Background/YellowButton
@onready var blue_button: Sprite2D = $Background/BlueButton
@onready var green_button: Sprite2D = $Background/GreenButton

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
var button_pressed_offset: float = 10.0  # How much buttons move down when pressed

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
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Store button original positions
	_store_button_positions()
	
	# Start hidden
	position = hidden_position
	visible = true  # Keep visible for animations, but positioned off-screen
	is_visible = false
	
	# Find player
	_find_player()

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
	
	# Handle button animations when UI is visible
	if not is_visible:
		return
		
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		match key_code:
			KEY_1:
				_animate_button_press(0)  # Red button
			KEY_2:
				_animate_button_press(1)  # Yellow button
			KEY_3:
				_animate_button_press(2)  # Blue button
			KEY_4:
				_animate_button_press(3)  # Green button

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
	
	# Get original position
	var original_pos = button_original_positions[button_index]
	var pressed_pos = Vector2(original_pos.x, original_pos.y + button_pressed_offset)
	
	# Animate button press (down then back up)
	tween.tween_property(button, "position", pressed_pos, BUTTON_ANIM_DURATION)
	tween.tween_property(button, "position", original_pos, BUTTON_ANIM_DURATION)

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

# Public methods for external scripts to control button animations
func animate_red_button():
	_animate_button_press(0)

func animate_yellow_button():
	_animate_button_press(1)

func animate_blue_button():
	_animate_button_press(2)

func animate_green_button():
	_animate_button_press(3)

# Public methods for external control
func set_player_reference(player_node: Node):
	"""Set the player reference manually"""
	player = player_node
	print("CassetteButtonlessUI: Player reference set to ", player_node.name if player_node else "null")

func is_ui_visible() -> bool:
	"""Check if the UI is currently visible"""
	return is_visible
