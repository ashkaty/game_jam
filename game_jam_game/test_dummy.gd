extends Node2D

@onready var animation_player := $AnimationPlayer

func take_damage(amount: int) -> void:
	animation_player.play("hurt")
	print("Damage: ", amount)

func 
