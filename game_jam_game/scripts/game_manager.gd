extends Node2D
class_name GameManager

@onready var player: Player = $Player
# Simple UI - no complex connections needed

func _ready():
	# Add game to a group so other systems can find it
	add_to_group("game")
	print("Game Manager ready - Simple Cassette UI loaded")
