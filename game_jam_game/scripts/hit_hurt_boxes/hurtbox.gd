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
               var horiz_dir := sign(owner.global_position.x - hitbox.global_position.x)
               if horiz_dir == 0:
                       horiz_dir = 1 # default knock right if overlapping

               var dir: Vector2
               match hitbox.attack_dir:
                       "up":
                               dir = Vector2(horiz_dir * 0.2, -1)
                       "down":
                               dir = Vector2(horiz_dir * 0.2, 1)
                       "side":
                               dir = Vector2(horiz_dir, -0.2)
                       _:
                               dir = Vector2(horiz_dir, -0.5)

               dir = dir.normalized()
               owner.apply_knockback(dir * hitbox.knockback_multiplier)
