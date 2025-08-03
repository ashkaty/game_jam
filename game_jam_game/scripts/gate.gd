extends StaticBody2D

@export_enum("red", "blue", "yellow") var color: String = "red"
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var rect: ColorRect = get_node_or_null("ColorRect")

var _is_open: bool = false
var _buttons_pressed_count: int = 0

func _ready() -> void:
	add_to_group("gate")
	_update_color()
	_set_open(false)
	print("Gate(", name, ",", color, ") ready. shape:", shape, " rect:", rect)

func notify_button_pressed() -> void:
	_buttons_pressed_count += 1
	_set_open(true)

func notify_button_released() -> void:
	_buttons_pressed_count = max(0, _buttons_pressed_count - 1)
	if _buttons_pressed_count == 0:
		_set_open(false)

func _set_open(open_state: bool) -> void:
	if _is_open == open_state:
		return
	_is_open = open_state
	if rect:
		rect.visible = not _is_open
	if shape:
		shape.disabled = _is_open
	print("Gate(", name, ") open:", _is_open)

func _update_color() -> void:
	if rect:
		match color:
			"red":
				rect.color = Color(1.0, 0.2, 0.2)
			"blue":
				rect.color = Color(0.2, 0.6, 1.0)
			"yellow":
				rect.color = Color(1.0, 0.85, 0.2)
