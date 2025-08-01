class_name DamageParticleManager

extends Node

# Preload the damage particle scene
var damage_particle_scene: PackedScene

func _ready() -> void:
	# Add to a group so other systems can find us
	add_to_group("damage_particle_manager")
	
	# Load the damage particle scene
	damage_particle_scene = preload("res://scenes/damage_particle.tscn")

func spawn_damage_particle(damage_amount: int, world_position: Vector2) -> void:
	if damage_particle_scene == null:
		print("Error: damage_particle_scene is null!")
		return
	
	# Instance the damage particle
	var particle = damage_particle_scene.instantiate() as DamageParticle
	if particle == null:
		print("Error: Failed to instantiate damage particle!")
		return
	
	# Add it to the scene tree (as a child of the current scene root)
	get_tree().current_scene.add_child(particle)
	
	# Setup the particle with damage amount and position
	particle.setup_damage_text(damage_amount, world_position)
	
	print("Spawned damage particle: ", damage_amount, " at ", world_position)

# Static method to easily spawn particles from anywhere
static func spawn_damage_text(damage_amount: int, world_position: Vector2) -> void:
	var manager = Engine.get_main_loop().get_nodes_in_group("damage_particle_manager")
	if manager.size() > 0:
		manager[0].spawn_damage_particle(damage_amount, world_position)
	else:
		print("Error: No DamageParticleManager found in scene!")
