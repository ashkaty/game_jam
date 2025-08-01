# Head Bonk Mechanic

This implementation adds a Minecraft-style "head bonk" mechanic to your Godot platformer. When the player jumps and hits their head on a ceiling/block above them, it gives them a horizontal speed boost in the direction they're facing.

## How It Works

### Core Mechanic
- When the player hits a ceiling while moving upward during a jump, they receive a horizontal speed boost
- The boost is applied in the direction the player is facing (left/right)
- The player's upward velocity is stopped and they get a small downward impulse (like in Minecraft)

### Key Features

1. **Grace Period**: Head bonk only works during the first 0.1 seconds of a jump for authentic feel
2. **Minimum Speed Requirement**: Player must be moving upward fast enough (velocity.y < -100) for the bonk to trigger
3. **Speed Scaling**: The faster you were moving upward, the stronger the horizontal boost (0.5x to 2x multiplier)
4. **Cooldown**: 0.3 second cooldown prevents multiple bonks in quick succession
5. **Speed Limiting**: Maximum horizontal speed is capped to prevent infinite acceleration
6. **Enhanced Air Control**: After a head bonk, player gets improved air control for 0.5 seconds
7. **Visual Feedback**: Player flashes yellow and camera shakes briefly when bonk occurs
8. **Signal System**: Emits a signal when head bonk occurs for particle effects, UI feedback, etc.

## Configuration

You can adjust these exported variables in the Player scene:

- `head_bonk_speed_boost` (300.0): Base horizontal speed added when bonking
- `head_bonk_grace_period` (0.1): Time window after jump start when bonk can occur
- `head_bonk_vertical_impulse` (50.0): Small downward push after bonk
- `head_bonk_minimum_upward_velocity` (-100.0): Minimum upward speed required for bonk

In the Jump state:
- `head_bonk_air_control_boost` (1.5): Multiplier for enhanced air control after bonk
- `head_bonk_control_duration` (0.5): How long enhanced air control lasts

## Implementation Details

### Files Modified:
1. **player.gd**: Added head bonk detection and handling
2. **jump.gd**: Added head bonk checking during jump state
3. **fall.gd**: Added head bonk checking during fall state (for edge cases)

### Key Functions:
- `check_and_handle_head_bonk()`: Detects ceiling collision and triggers bonk
- `perform_head_bonk()`: Applies the speed boost and effects

### Signal:
- `head_bonk_occurred(boost_amount: float, direction: int)`: Emitted when bonk happens

## Usage Tips

1. **Level Design**: Create low ceilings near platforms to enable strategic head bonking
2. **Speedrunning**: Players can chain head bonks for momentum in tight spaces
3. **Combat**: Can be used to quickly escape or reposition during fights
4. **Particle Effects**: Connect to the `head_bonk_occurred` signal to add visual feedback

## Testing

To test the mechanic:
1. Jump toward a low ceiling/platform
2. Make sure you hit your head while moving upward
3. You should get a horizontal speed boost in your facing direction
4. Watch the console for "HEAD BONK!" messages

The mechanic works best with level geometry that has overhangs, low ceilings, or platforms the player can jump into from below.
