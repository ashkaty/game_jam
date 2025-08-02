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
	
	print("Game Manager ready - Buttonless Cassette UI loaded")
