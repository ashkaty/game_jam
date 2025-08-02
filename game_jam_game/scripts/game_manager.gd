extends Node2D
class_name GameManager

@onready var player: Player = $Player
@onready var cassette_ui: CassetteButtonlessUI = $UI/CassetteButtonlessUI

func _ready():
	# Add game to a group so other systems can find it
	add_to_group("game")
	
	# Set up UI connections
	if cassette_ui and player:
		cassette_ui.set_player_reference(player)
	
	print("Game Manager ready - Buttonless Cassette UI loaded")
