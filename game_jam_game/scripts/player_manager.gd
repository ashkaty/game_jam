class_name PlayerManager

extends Node2D

	# The Player scene to instance per track
@export var track_scene: PackedScene
@export var track_count: int = 4

	# Holds the instantiated Player tracks
var tracks: Array[Player] = []
# Index of the currently active track
var active_track_idx: int = 0

func _ready() -> void:
	# Instantiate and set up each track
	for i in range(track_count):
		var player = track_scene.instantiate() as Player
		player.name = "Track%d" % i
		
		player.position = Vector2( i * 32, 0 )  # 32-pixel horizontal offset per track
		add_child(player)
		# Listen for when the player’s ring buffer starts looping
		player.connect("loop_started", Callable(self, "_on_loop_started").bind(i))
		tracks.append(player)
		# Disable input on all until we activate one
		player.set_process_input(false)

	# Activate the first track by default
	active_track_idx = 0
	activate_track(active_track_idx)

# Intercept unhandled input and forward only to the active track
func _unhandled_input(event: InputEvent) -> void:
	tracks[active_track_idx]._unhandled_input(event)

# Called when a track’s ring buffer becomes full and starts replaying
func _on_loop_started(looping_track_idx: int) -> void:
	# Only switch if it’s from the active track
	if looping_track_idx != active_track_idx:
		return
	# Compute next track index (wraps around)
	var next_idx = (active_track_idx + 1) % tracks.size()
	activate_track(next_idx)

# Enable input on the chosen track, disable on the others
func activate_track(idx: int) -> void:
	for i in range(tracks.size()):
		tracks[i].set_process_input(i == idx)
	active_track_idx = idx
	print("[PlayerManager] Switched to track %d" % idx)
