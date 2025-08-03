extends StaticBody2D

@export var next_level: PackedScene
@export var require_activator: bool = true
@export var auto_size_vertical_bar: bool = true
@export var bar_width_px: float = 10.0
@export var bar_color: Color = Color(1.0, 0.2, 0.2, 1.0)

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var rect: ColorRect = get_node_or_null("ColorRect")
@onready var sensor: Area2D = get_node_or_null("Sensor")
@onready var sensor_shape: CollisionShape2D = get_node_or_null("Sensor/CollisionShape2D")

func _ready() -> void:
	_ensure_sensor()
	if auto_size_vertical_bar:
		_resize_bar_to_viewport()
	if rect:
		rect.color = bar_color
	_print_debug("ready")

func _ensure_sensor() -> void:
	if not sensor:
		sensor = Area2D.new()
		sensor.name = "Sensor"
		add_child(sensor)
	if not sensor_shape:
		sensor_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(bar_width_px, 64.0)
		sensor_shape.shape = rs
		sensor.add_child(sensor_shape)
	# Match layers/masks so it can see your player/tracks
	sensor.collision_layer = collision_layer
	sensor.collision_mask = collision_mask
	sensor.monitoring = true
	sensor.monitorable = true
	if not sensor.body_entered.is_connected(_on_body_entered):
		sensor.body_entered.connect(_on_body_entered)
	_print_debug("sensor wired")

func _on_body_entered(body: Node) -> void:
	_print_debug("enter from %s groups=%s" % [body.name, body.get_groups()])
	if not next_level:
		printerr("LevelChanger:", name, " has no next_level set.")
		return
	if require_activator and not _is_activator(body):
		_print_debug("ignored: not activator")
		return
	_change_level()

func _is_activator(n: Node) -> bool:
	if n.is_in_group("activator"):
		return true
	if n.name == "Player":
		return true
	if n.name.begins_with("Track"):
		return true
	return false

func _change_level() -> void:
	_print_debug("changing level...")
	# Prevent re-trigger
	if sensor:
		sensor.monitoring = false
	# Small defer so logs flush
	await get_tree().process_frame
	get_tree().change_scene_to_packed(next_level)

func _resize_bar_to_viewport() -> void:
	var h := get_viewport_rect().size.y
	var body_rect := shape.shape as RectangleShape2D
	if body_rect:
		body_rect.size = Vector2(bar_width_px, h)
	if rect:
		rect.anchor_left = 0.0
		rect.anchor_top = 0.0
		rect.anchor_right = 0.0
		rect.anchor_bottom = 0.0
		rect.size = Vector2(bar_width_px, h)
		rect.position = Vector2.ZERO
	if sensor_shape and sensor_shape.shape is RectangleShape2D:
		(sensor_shape.shape as RectangleShape2D).size = Vector2(bar_width_px, h)

func _print_debug(tag: String) -> void:
	print("LevelChanger[", name, "] ", tag, " next=",
		next_level if next_level else "null",
		" layer=", collision_layer, " mask=", collision_mask,
		" sensor_layer=", sensor.collision_layer if sensor else -1,
		" sensor_mask=", sensor.collision_mask if sensor else -1)
