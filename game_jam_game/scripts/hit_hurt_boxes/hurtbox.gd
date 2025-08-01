class_name HurtBox

extends Area2D


func _init() -> void:
	collision_layer = 0
	collision_mask = 4

func _ready() -> void:
	connect("area_entered", self._on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
		
	if owner.has_method("apply_knockback"):
		var dir: Vector2 = (owner.global_position - hitbox.global_position).normalized()
		owner.apply_knockback(dir * hitbox.knockback_multiplier)
