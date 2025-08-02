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
	
	# Get the actual damage (which may include fast fall multiplier)
	var actual_damage = hitbox.get_damage()
	
	if owner.has_method("take_damage"):
		owner.take_damage(actual_damage)
		
		# Trigger camera shake based on damage amount
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("shake_camera_for_damage"):
			player.shake_camera_for_damage(actual_damage)
		
		# Calculate spawn position based on the collision shape bounds
		var collision_shape = $CollisionShape2D
		if collision_shape and collision_shape.shape:
			# Get the top of the collision bounds
			var shape_top = collision_shape.global_position.y - (collision_shape.shape.get_rect().size.y * collision_shape.scale.y / 2)
			var spawn_position = Vector2(
				collision_shape.global_position.x + randf_range(-20, 20),
				shape_top - 20  # Spawn 20 pixels above the top of the collision shape
			)
			DamageParticleManager.spawn_damage_text(actual_damage, spawn_position)
		else:
			# Fallback: use hurtbox position with upward offset
			var spawn_position = global_position + Vector2(randf_range(-15, 15), -80)
			DamageParticleManager.spawn_damage_text(actual_damage, spawn_position)
		
	if owner.has_method("apply_knockback"):
		var dir: Vector2 = (owner.global_position - hitbox.global_position).normalized()
		owner.apply_knockback(dir * hitbox.knockback_multiplier)
