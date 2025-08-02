class_name HitBox

extends Area2D

@export
var damage := 10
@export 
var knockback_multiplier: float = 200.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	collision_shape_2d.disabled = true

# Calculate the actual damage to deal, considering fast fall multiplier
func get_damage() -> int:
	# Try to get the player to calculate fast fall damage multiplier
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_fast_fall_damage_multiplier"):
		var multiplier = player.get_fast_fall_damage_multiplier()
		var final_damage = int(damage * multiplier)
		
		# Trigger motion blur for high-damage attacks
		if player.has_method("trigger_motion_blur_burst") and final_damage > damage * 2.0:
			var blur_intensity = clamp((multiplier - 1.0) * 0.3, 0.1, 0.6)
			player.trigger_motion_blur_burst(blur_intensity, 0.2)
		
		return final_damage
	else:
		return damage
	

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	print("animation start")
	collision_shape_2d.disabled = false


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	collision_shape_2d.disabled = true
