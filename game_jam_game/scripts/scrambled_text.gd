extends Control
class_name FancyScrambleText

@export var text: String = "HELLO, WORLD!" 
@export var duration: float = 1.2
@export var delay: float = 0.0
@export var autoplay: bool = true

@export var ease_curve: Curve

@export var scramble_chars: String = \
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"

@export var scramble_letters_only: bool = true

@export var font: Font
@export var font_size: int = 32
@export var font_color: Color = Color(1, 1, 1, 1)
@export var font_outline_size: int = 0
@export var font_outline_color: Color = Color(0, 0, 0, 0.6)

@export var shadow_enabled: bool = true
@export var shadow_color: Color = Color(0, 0, 0, 0.5)
@export var shadow_offset: Vector2 = Vector2(2, 2)

@onready var _label: Label = $Label

var _time: float = 0.0
var _playing: bool = false

var _target: String = ""
var _current: PackedStringArray = PackedStringArray()
var _order: PackedInt32Array = PackedInt32Array()
var _locked_count: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_apply_label_style()
	_initialize_strings(text)
	if autoplay:
		play()

func _process(delta: float) -> void:
	if not _playing:
		return

	_time = _time + delta
	if _time < delay:
		return

	var n: int = _target.length()
	if n == 0:
		_label.text = ""
		_playing = false
		return

	var t: float = (_time - delay) / max(duration, 0.0001)
	if t < 0.0:
		t = 0.0
	if t > 1.0:
		t = 1.0
	t = _apply_curve(t)

	var target_locked: int = int(floor(lerp(0.0, float(n), t)))

	while _locked_count < target_locked:
		var idx: int = _order[_locked_count]
		_current[idx] = _target.substr(idx, 1)
		_locked_count = _locked_count + 1

	for i in range(_locked_count, n):
		var idx2: int = _order[i]
		if _should_scramble_index(idx2):
			_current[idx2] = _rand_char_for(_target.substr(idx2, 1))
		else:
			_current[idx2] = _target.substr(idx2, 1)

	_label.text = "".join(_current)

	if _locked_count >= n:
		_playing = false

func play() -> void:
	_time = 0.0
	_playing = true
	_prepare_from_target()

func reset() -> void:
	_playing = false
	_time = 0.0
	if _target == "":
		_initialize_strings(text)
	else:
		_initialize_strings(_target)

func set_text(value: String) -> void:
	text = value
	if is_instance_valid(_label):
		_initialize_strings(text)
		if autoplay:
			play()

func set_font(new_font: Font) -> void:
	font = new_font
	if is_instance_valid(_label):
		_apply_label_style()
		_auto_size_to_text()

func set_font_size(new_size: int) -> void:
	font_size = new_size
	if is_instance_valid(_label):
		_apply_label_style()
		_auto_size_to_text()

# ---------------- Internals ----------------

func _apply_curve(t: float) -> float:
	if ease_curve and ease_curve.get_point_count() > 0:
		return ease_curve.sample_baked(t)
	return 1.0 - pow(1.0 - t, 3.0)

func _apply_label_style() -> void:
	if font:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", font_color)

	_label.add_theme_constant_override("outline_size", font_outline_size)
	_label.add_theme_color_override("font_outline_color", font_outline_color)

	if shadow_enabled:
		_label.add_theme_color_override("shadow_color", shadow_color)
		_label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		_label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	else:
		_label.add_theme_color_override("shadow_color", Color(0, 0, 0, 0))
		_label.add_theme_constant_override("shadow_offset_x", 0)
		_label.add_theme_constant_override("shadow_offset_y", 0)

	_label.clip_text = false
	_auto_size_to_text()

func _auto_size_to_text() -> void:
	await get_tree().process_frame
	_label.size = _label.get_minimum_size()
	size = _label.size

func _initialize_strings(new_target: String) -> void:
	_target = new_target
	var n: int = _target.length()
	_current.resize(n)
	_order = _make_random_order(n)
	_locked_count = 0

	for i in range(n):
		if _should_scramble_index(i):
			_current[i] = _rand_char_for(_target.substr(i, 1))
		else:
			_current[i] = _target.substr(i, 1)

	_label.text = "".join(_current)
	_auto_size_to_text()

func _prepare_from_target() -> void:
	var n: int = _target.length()
	_order = _make_random_order(n)
	_locked_count = 0

	for i in range(n):
		if _should_scramble_index(i):
			_current[i] = _rand_char_for(_target.substr(i, 1))
		else:
			_current[i] = _target.substr(i, 1)

	_label.text = "".join(_current)

func _make_random_order(n: int) -> PackedInt32Array:
	var arr: PackedInt32Array = PackedInt32Array()
	arr.resize(n)
	var i: int = 0
	while i < n:
		arr[i] = i
		i = i + 1
	i = n - 1
	while i > 0:
		var j: int = _rng.randi_range(0, i)
		var tmp: int = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
		i = i - 1
	return arr

# target_ch is a 1-character String
func _rand_char_for(target_ch: String) -> String:
	if scramble_chars.is_empty():
		return target_ch

	var index: int = _rng.randi_range(0, scramble_chars.length() - 1)
	# Get one-character substring instead of chr()
	var s: String = scramble_chars.substr(index, 1)

	# Match case to the target if alphabetic
	var is_alpha: bool = target_ch.to_upper() != target_ch.to_lower()
	if is_alpha:
		var target_is_upper: bool = target_ch == target_ch.to_upper()
		if target_is_upper:
			s = s.to_upper()
		else:
			s = s.to_lower()
	return s

func _should_scramble_index(i: int) -> bool:
	if not scramble_letters_only:
		return true
	var ch: String = _target.substr(i, 1)
	return ch.to_upper() != ch.to_lower()
