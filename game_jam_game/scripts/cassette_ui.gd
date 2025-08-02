extends Control
class_name CassetteUI

@onready var info_label: RichTextLabel = $ContentContainer/InfoContainer/InfoLabel
@onready var title_label: Label = $ContentContainer/TitleLabel
@onready var close_button: Button = $CloseButton

# Player reference for getting real-time data
var player: Node = null

# UI visibility state
var is_visible: bool = false

# Information to display
var player_health: int = 100
var player_max_health: int = 100
var player_score: int = 0
var player_level: int = 1
var current_info_text: String = ""

signal ui_closed

func _ready():
	# Hide the UI initially
	hide()
	
	# Connect the close button
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Set up initial state
	is_visible = false
	
	# Look for player in the scene
	_find_player()
	
	# Update display
	update_display()

func _find_player():
	# Try to find the player node in the scene
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node:
		player = game_node.get_node_or_null("Player")
	
	if not player:
		# Alternative search
		player = get_tree().get_first_node_in_group("player")

func _input(event):
	# Toggle UI with Tab key or the defined input action
	if event.is_action_pressed("toggle_cassette_ui"):
		toggle_ui()

func toggle_ui():
	"""Toggle the visibility of the cassette UI"""
	if is_visible:
		hide_ui()
	else:
		show_ui()

func show_ui():
	"""Show the cassette UI with updated information"""
	update_display()
	show()
	is_visible = true
	# Optionally pause the game when UI is shown
	# get_tree().paused = true

func hide_ui():
	"""Hide the cassette UI"""
	hide()
	is_visible = false
	# Unpause if was paused
	# get_tree().paused = false
	ui_closed.emit()

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_ui()

func update_display():
	"""Update the displayed information"""
	# Update player stats if player reference exists
	if player and player.has_method("get_health"):
		player_health = player.get_health()
	if player and player.has_method("get_max_health"):
		player_max_health = player.get_max_health()
	if player and player.has_method("get_score"):
		player_score = player.get_score()
	if player and player.has_method("get_level"):
		player_level = player.get_level()
	
	# Format the information text
	var info_text = ""
	info_text += "[b]Health:[/b] %d/%d\n" % [player_health, player_max_health]
	info_text += "[b]Score:[/b] %d\n" % player_score
	info_text += "[b]Level:[/b] %d\n" % player_level
	
	# Add custom information if available
	if current_info_text != "":
		info_text += "\n[color=blue]" + current_info_text + "[/color]"
	
	# Update the label
	info_label.text = info_text

func set_custom_info(text: String):
	"""Set custom information to display on the cassette"""
	current_info_text = text
	if is_visible:
		update_display()

func set_title(title: String):
	"""Set the title of the cassette UI"""
	title_label.text = title

func set_player_reference(player_node: Node):
	"""Set the player reference manually"""
	player = player_node

# Methods for updating specific stats (can be called from other scripts)
func update_health(health: int, max_health: int = -1):
	player_health = health
	if max_health > 0:
		player_max_health = max_health
	if is_visible:
		update_display()

func update_score(score: int):
	player_score = score
	if is_visible:
		update_display()

func update_level(level: int):
	player_level = level
	if is_visible:
		update_display()

func _process(delta):
	# Auto-update display if visible
	if is_visible:
		update_display()
