# Knockback System

## Overview
The knockback system provides directional, physics-based knockback for attacks. It includes attack-specific knockback directions, proper physics collision, and visual feedback for impacts.

## How It Works

### Components
1. **HitBox** (`scripts/hit_hurt_boxes/hitbox.gd`) - Attached to attacking objects (like the sword)
2. **HurtBox** (`scripts/hit_hurt_boxes/hurtbox.gd`) - Attached to objects that can be hit
3. **apply_knockback()** method - Must be implemented by objects that can be knocked back
4. **CharacterBody2D** - Used for physics-based entities (like test dummy)

### Directional Knockback System

#### Attack-Specific Directions
The system automatically determines knockback direction based on:
- **Attack type** (upward, downward, regular swing)
- **Player facing direction** (left/right)

**Upward Swing** (`up_ward_swing`):
- Force: 150 (weaker)
- Direction: Diagonal up-back (Vector2(±0.7, -0.8))
- Perfect for launching enemies into the air

**Downward Swing** (`down_ward_swing`):
- Force: 300 (stronger)  
- Direction: Horizontal with slam effect (Vector2(±1.0, 0.3))
- Great for powerful knockdowns

**Regular Swing** (`swing`):
- Force: 200 (standard)
- Direction: Pure horizontal (Vector2(±1.0, 0.0))
- Reliable combat knockback

#### Physics Integration
- **Test Dummy**: Now uses CharacterBody2D with proper physics
- **Gravity**: Applied when airborne
- **Friction**: Ground and air resistance for realistic movement
- **Collision**: Proper collision detection with environment

### Visual Effects
- Camera shake scaled to knockback strength
- Motion blur bursts for strong impacts  
- Sprite flashing on significant knockback
- Debug output showing attack types and directions

## Testing the System

### Basic Testing
1. **Horizontal Attacks**: Attack dummy while facing different directions
2. **Upward Attacks**: Hold UP while attacking to launch enemies
3. **Downward Attacks**: Hold DOWN/CROUCH while attacking for slam effect
4. **Physics**: Watch dummy fall with gravity and slide with friction

### Expected Behaviors
- **Right-facing upward attack**: Dummy flies up and to the right
- **Left-facing downward attack**: Dummy slams left and slightly down
- **Regular attacks**: Clean horizontal knockback in facing direction
- **Physics**: Dummy should bounce off walls, fall with gravity, slide to stop

## Customization

### Knockback Values (HitBox.gd)
```gdscript
@export var upward_attack_knockback_multiplier: float = 150.0
@export var downward_attack_knockback_multiplier: float = 300.0  
@export var regular_attack_knockback_multiplier: float = 200.0
```

### Physics Settings (test_dummy.gd)
```gdscript
@export var gravity: float = 980.0
@export var friction: float = 0.8
@export var knockback_resistance: float = 1.0
@export var max_knockback_velocity: float = 800.0
```

### Adding New Enemies
For physics-based enemies:
```gdscript
extends CharacterBody2D

@export var gravity: float = 980.0
@export var knockback_resistance: float = 0.8

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    velocity.x *= 0.9  # Friction
    move_and_slide()

func apply_knockback(knockback_force: Vector2):
    velocity += knockback_force * knockback_resistance
```

## Implementation Details

### Direction Calculation
The system uses player facing direction and attack type to determine knockback:
- Positive X = Right, Negative X = Left
- Negative Y = Up, Positive Y = Down
- Vectors are normalized for consistent force application

### Physics Integration
- CharacterBody2D handles collision with environment
- Gravity and friction create realistic movement
- Velocity clamping prevents physics breaking
- Works with Godot's built-in collision system

### Debug Features
- Console output shows attack types and directions
- Knockback forces and resulting velocities logged
- Player facing direction tracked
- Animation state monitoring

## Notes
- All entities need proper CollisionShape2D for physics
- HurtBox and CharacterBody2D use separate collision shapes
- System integrates with existing camera shake and motion blur
- Fast fall attacks still get damage multipliers
- Easy to extend for new attack types and enemy behaviors
