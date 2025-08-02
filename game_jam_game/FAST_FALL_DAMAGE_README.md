# Fast Fall Damage Mechanic

This implementation adds a damage multiplier system that increases damage dealt when the player is fast falling. The faster you fall, the more damage you deal!

## How It Works

### Core Mechanic
- When the player is fast falling (holding crouch or shift) and moving downward fast enough, all attacks deal bonus damage
- The damage multiplier scales with fall speed - faster falls = more damage
- Works with all attack types, but is especially effective with downward air attacks

### Key Features

1. **Speed-Based Scaling**: Damage multiplier increases based on fall velocity
2. **Minimum Speed Threshold**: Must be falling at least 800 units/second to trigger bonus damage
3. **Progressive Scaling**: Damage multiplier ranges from 2.5x to 4.0x at terminal velocity
4. **Downward Air Attack Boost**: Performing a downward attack while fast falling adds extra downward velocity
5. **Visual Feedback**: Console messages show when fast fall damage is active

## Configuration

You can adjust these exported variables in the Player scene:

- `fast_fall_damage_multiplier` (2.5): Base damage multiplier when fast falling
- `fast_fall_minimum_speed` (800.0): Minimum fall speed required to trigger bonus damage
- `max_fast_fall_damage_multiplier` (4.0): Maximum damage multiplier at terminal velocity

In the Air Attack state:
- `downward_attack_speed_boost` (400.0): Extra downward velocity added during downward air attacks

## Implementation Details

### Files Modified:
1. **player.gd**: Added fast fall damage calculation system
2. **hitbox.gd**: Modified to use dynamic damage calculation
3. **hurtbox.gd**: Updated to use the new damage system
4. **air_attack.gd**: Enhanced downward attacks for fast falling

### Key Functions:
- `get_fast_fall_damage_multiplier()`: Calculates damage multiplier based on current velocity and input state

## Usage Tips

1. **Aerial Combat**: Hold crouch/shift while falling to build up speed before attacking
2. **Downward Slam**: Use crouch + attack while fast falling for maximum damage
3. **Speed Building**: Combine with fast fall mechanics to reach terminal velocity quickly
4. **Strategic Positioning**: Position yourself above enemies to take advantage of gravity

## Damage Scaling Examples

- Normal attack: 10 damage
- Fast falling at minimum speed (800 units/s): 25 damage (2.5x multiplier)
- Fast falling at moderate speed (1800 units/s): 32 damage (3.2x multiplier)  
- Fast falling at terminal velocity (3000 units/s): 40 damage (4.0x multiplier)

## Testing

To test the mechanic:
1. Jump into the air and hold crouch or shift to fast fall
2. Attack enemies while falling at high speed
3. Watch the console for "Fast fall damage!" messages
4. Try the downward air attack (crouch + attack) for extra velocity boost
5. Check damage numbers - they should be significantly higher than normal attacks
