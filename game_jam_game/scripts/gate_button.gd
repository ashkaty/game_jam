extends Area2D

@export_enum("red", "blue", "yellow") var color: String = "red"
@onready var rect: ColorRect = get_node_or_null("ColorRect")

var _matching_gates: Array[Node] = []
var _is_pressed: bool = false
var _overlap_count: int = 0

func _ready() -> void:
	add_to_group("gate_button")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_cache_matching_gates()
	_update_color()
	print("Button(", name, ",", color, ") matched gates:", _matching_gates)

func _is_activator(n: Node) -> bool:
	return n.is_in_group("activator") or n.name == "Player" or n.name.begins_with("Track")

func _on_body_entered(body: Node) -> void:
	if _is_activator(body):
		_overlap_count += 1
		_try_set_pressed(true)

func _on_body_exited(body: Node) -> void:
	if _is_activator(body):
		_overlap_count = max(0, _overlap_count - 1)
		if _overlap_count == 0:
			_try_set_pressed(false)

func _try_set_pressed(pressed: bool) -> void:
	if _is_pressed == pressed:
		return
	_is_pressed = pressed
	if rect:
		rect.modulate = Color(0.8, 0.8, 0.8) if pressed else Color(1, 1, 1)
	print("Button(", name, ") pressed:", pressed, " -> notify ", _matching_gates.size(), " gates")
	for g in _matching_gates:
		if pressed:
			g.notify_button_pressed()
		else:
			g.notify_button_released()

func _cache_matching_gates() -> void:
	_matching_gates.clear()
	for gate in get_tree().get_nodes_in_group("gate"):
		if "color" in gate and gate.color == color:
			_matching_gates.append(gate)

func _update_color() -> void:
	if not rect:
		return
	match color:
		"red":
			rect.color = Color(1.0, 0.2, 0.2)
		"blue":
			rect.color = Color(0.2, 0.6, 1.0)
		"yellow":
			rect.color = Color(1.0, 0.85, 0.2)
