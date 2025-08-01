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

# Player reference
var player: Node = null

# UI state
var is_visible: bool = false
var slide_tween: Tween
var original_position: Vector2
var hidden_position: Vector2

# Animation settings
const SLIDE_DURATION: float = 0.3
const SLIDE_EASE_TYPE = Tween.EASE_OUT
const SLIDE_TRANS_TYPE = Tween.TRANS_BACK

signal ui_toggled(visible: bool)

func _ready():
	# Store original positions for animation
	original_position = position
	hidden_position = Vector2(original_position.x, get_viewport().get_visible_rect().size.y + 50)
	
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
	if node.name == "Player" or node is Player:
		return node
	
	for child in node.get_children():
		var result = _search_for_player(child)
		if result:
			return result
	
	return null

func _input(event):
	if event.is_action_pressed("toggle_cassette_ui"):
		toggle_ui()

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

# Animation event handlers
func _on_slide_animation_finished():
	"""Called when slide animation completes"""
	if not is_visible:
		# UI is now fully hidden
		pass
	else:
		# UI is now fully shown
		pass
