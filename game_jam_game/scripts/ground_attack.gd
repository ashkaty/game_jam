extends State

@export var idle_state: State
@export var move_state: State
@export var fall_state: State
@export var jump_state: State
@export var crouch_state: State
@export var dash_state: State
# -- Parameters -- #
@export var deceleration: float
@export var animation_name: String = "base_attack"
@export var base_attack_speed_mult: float = 1.0
@export var up_attack_speed_mult: float = 1.0
@export var down_attack_speed_mult: float = 1.0

func enter() -> void:
        animation_speed_mult = base_attack_speed_mult
        super()

        # Start cancelable action tracking
        parent.start_cancelable_action("ground_attack")

        # Preserve facing direction when entering attack state
        var input_axis = Input.get_axis("move_left", "move_right")
        if input_axis != 0.0:
                parent.set_facing_left(input_axis < 0)

func process_input(_event: InputEvent) -> State:
        # Input processing moved to process_frame for polling system
        return null

func process_frame(delta: float) -> State:
        # Check for action cancellation first
        if parent.is_trying_to_cancel_with_movement():
                parent.end_current_action()
                return move_state

        if parent.is_trying_to_cancel_with_jump() and parent.can_jump():
                parent.end_current_action()
                return jump_state

        if parent.is_trying_to_cancel_with_dash() and dash_state and dash_state.is_dash_available():
                parent.end_current_action()
                return dash_state

        if parent.is_action_pressed_polling("up"):
                parent.animations.play("up_attack", -1, up_attack_speed_mult)
                print("Playing Upward Attack Animation")
                parent.end_current_action()
                return idle_state
        elif parent.is_action_pressed_polling("crouch"):
                parent.animations.play("down_attack", -1, down_attack_speed_mult)
                print("Playing Downward Attack Animation")
                parent.end_current_action()
                return crouch_state
        else:
                parent.animations.play("base_attack", -1, base_attack_speed_mult)
                print("Playing Base Attack Animation")
                parent.end_current_action()
                return idle_state

        return null

func process_physics(delta: float) -> State:
        parent.velocity.x = move_toward(parent.velocity.x, 0.0, deceleration * delta)
        parent.move_and_slide()
        return null
