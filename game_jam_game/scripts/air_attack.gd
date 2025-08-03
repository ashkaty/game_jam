extends State

@export var fall_state: State
@export var idle_state: State
@export var move_state: State
@export var dash_state: State
# @export var animation_name: String = "air attack"
@export var base_attack_speed_mult: float = 1.0
@export var up_attack_speed_mult: float = 1.0
@export var down_attack_speed_mult: float = 1.0

# Air attack specific properties removed for simplicity

func enter() -> void:
		animation_speed_mult = base_attack_speed_mult
		super()
		parent.start_cancelable_action("air_attack")

func process_input(_event: InputEvent):
		return null

func process_frame(delta: float) -> State:
		if parent.is_trying_to_cancel_with_dash() and dash_state and dash_state.is_dash_available():
				parent.end_current_action()
				return dash_state

		if parent.is_action_pressed_polling("up"):
				parent.animations.play("up_attack", -1, up_attack_speed_mult)
				parent.end_current_action()
				return fall_state
		elif parent.is_action_pressed_polling("crouch"):
				parent.animations.play("down_attack", -1, down_attack_speed_mult)
				parent.end_current_action()
				return fall_state
		else:
				parent.animations.play("air attack", -1, base_attack_speed_mult)
				parent.end_current_action()
				return fall_state

		return null

func process_physics(delta: float) -> State:
		parent.velocity.y += gravity * delta

		var input_axis: float = Input.get_axis("move_left", "move_right")
		if input_axis != 0.0:
				var air_accel = 100.0
				var max_air_speed = 300.0
				var air_direction_change_multiplier = 1.5
				var target_speed = input_axis * max_air_speed
				var is_changing_direction = (input_axis > 0 and parent.velocity.x < 0) or (input_axis < 0 and parent.velocity.x > 0)
				var effective_air_accel = air_accel
				if is_changing_direction:
						effective_air_accel = air_accel * air_direction_change_multiplier
				parent.velocity.x = move_toward(parent.velocity.x, target_speed, effective_air_accel * delta)
				parent.set_facing_left(input_axis < 0)
		else:
				var air_friction = 200.0
				parent.velocity.x = move_toward(parent.velocity.x, 0.0, air_friction * delta)

		parent.move_and_slide()

		if parent.is_on_floor():
				return null

		return null
