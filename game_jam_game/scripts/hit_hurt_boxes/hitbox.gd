class_name HitBox

extends Area2D

@export
var damage := 10
@export
var knockback_multiplier: float = 200.0
@export
var attack_dir: String = "side"  # "up", "down", or "side"

func _init() -> void:
	collision_layer = 4
	collision_mask = 0
