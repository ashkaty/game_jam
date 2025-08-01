extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var ground_friction: float = 800.0
@export var max_knockback_speed: float = 600.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _was_on_floor: bool = true

func _physics_process(delta: float) -> void:
		rotation = 0.0
		if not is_on_floor():
				velocity.y += gravity * delta
				if animation_player.has_animation("fall"):
						if animation_player.current_animation != "fall":
								animation_player.play("fall")
		else:
				if not _was_on_floor:
						if animation_player.has_animation("land"):
								animation_player.play("land")
				velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
				if velocity.y > 0:
						velocity.y = 0
				if abs(velocity.x) < 1 and animation_player.has_animation("idle"):
						if animation_player.current_animation != "idle":
								animation_player.play("idle")
		move_and_slide()
		_was_on_floor = is_on_floor()

func take_damage(amount: int) -> void:
		if animation_player.has_animation("hurt"):
				animation_player.play("hurt")

func apply_knockback(force: Vector2) -> void:
		velocity += force
		if velocity.length() > max_knockback_speed:
				velocity = velocity.normalized() * max_knockback_speed
