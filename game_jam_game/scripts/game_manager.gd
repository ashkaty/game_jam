extends Node2D
class_name GameManager

@onready var player: Player = $Player
@onready var cassette_ui: CassetteButtonlessUI = $UI/CassetteButtonlessUI
@onready var game_camera: Camera2D = $Player/Camera2D

func _ready():
	# Add game to a group so other systems can find it
	add_to_group("game")
	
	# Add camera to a group so it can be found for shake effects
	if game_camera:
		game_camera.add_to_group("game_camera")
	
	# Set up UI connections
	if cassette_ui and player:
		cassette_ui.set_player_reference(player)
		# Connect to timer finished signal
		cassette_ui.timer_finished.connect(_on_timer_finished)
	
	print("Game Manager ready - Buttonless Cassette UI loaded with timer")

func _on_timer_finished():
	"""Called when the countdown timer reaches zero"""
	print("Game timer finished!")
	# Add any game-ending logic here, such as:
	# - Show game over screen
	# - Stop player movement
	# - Calculate final score
	# - etc.
var current_level: Node = null

func load_level(path: String):
	if current_level:
		current_level.queue_free()

	var level_scene = load(path)
	current_level = level_scene.instantiate()
	$LevelContainer.add_child(current_level)
