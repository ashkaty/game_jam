# Example script showing how to use the signal pattern
extends Node
class_name ExampleDamageSystem

# Reference to player manager
@export var player_manager: PlayerManager

func _ready():
	# Example: Connect to player manager events if needed
	pass

# Example function that could be called when player takes damage
func on_player_hit_by_enemy():
	print("Player was hit by enemy!")
	
	# Following the requested pattern: call player_manager's take_damage()
	if player_manager:
		player_manager.take_damage()  # This will emit("damage") to UI
	else:
		print("No player manager reference!")

# Example of triggering other cassette events
func on_cassette_button_pressed():
	if player_manager:
		player_manager.trigger_cassette_event("play")

func on_level_complete():
	if player_manager:
		player_manager.trigger_cassette_event("stop")

# Example of direct UI interaction (alternative approach)
func on_player_collect_health():
	# Get UI reference through player manager and add health
	if player_manager and player_manager.cassette_ui:
		player_manager.cassette_ui.gain_heart()
