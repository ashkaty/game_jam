class_name HitBox

extends Area2D

@export
var damage := 10
@export 
var knockback_multiplier: float = 200.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _init() -> void:
	collision_layer = 4
	collision_mask = 0
	#collision_shape_2d.disabled() = true
	#
#func to_enable() -> void:
	#collision_shape_2d.disabled = false
#
#func to_disable() -> void:
	#collision_shape_2d.disabled = true
