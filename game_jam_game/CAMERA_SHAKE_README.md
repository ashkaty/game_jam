# Camera Shake on Damage System

This implementation adds dynamic camera shake effects that scale with the amount of damage the player deals to enemies. The more damage you deal, the stronger the camera shake!

## How It Works

### Core Mechanic
- When the player deals damage to an enemy, the camera shakes with intensity proportional to the damage amount
- Low damage (1-10) creates subtle shake effects
- High damage (30-50+) creates dramatic screen shake for satisfying feedback
- The shake duration also scales with damage amount

### Key Features

1. **Damage-Scaled Intensity**: Shake strength scales from 2.0 to 15.0 based on damage (1-50 damage range)
2. **Duration Scaling**: Shake duration scales from 0.1 to 0.4 seconds based on damage
3. **Gradual Falloff**: Shake intensity gradually decreases over the duration for natural feel
4. **Dual Camera Support**: Works with both the player's camera and the game scene camera
5. **Fast Fall Integration**: Works seamlessly with the existing fast fall damage multiplier system
6. **Smooth Animation**: Uses 20 steps per second for smooth shake motion

## Configuration

The shake system automatically scales based on damage, but you can adjust these values in `player.gd`:

```gdscript
# In shake_camera_for_damage() function:
var base_shake = 2.0              # Minimum shake strength
var max_shake = 15.0              # Maximum shake strength  
var max_damage_for_scaling = 50.0 # Damage amount that triggers max shake
var base_duration = 0.1           # Minimum shake duration
var max_duration = 0.4            # Maximum shake duration
```

## Implementation Details

### Files Modified:
1. **player.gd**: Added camera shake system with damage scaling
2. **hurtbox.gd**: Modified to trigger camera shake when damage is dealt
3. **game_manager.gd**: Added camera group registration for easy access

### Key Functions:
- `shake_camera_for_damage(damage_amount: int)`: Main function that calculates and triggers shake
- `_perform_camera_shake(target_camera: Camera2D, shake_strength: float, duration: float)`: Performs the actual shake animation

### Integration Points:
- Automatically triggered when any enemy takes damage
- Works with existing damage particle system
- Integrates with fast fall damage multipliers
- Compatible with head bonk mechanic

## Usage Examples

### Damage Scaling Examples:
- **Basic attack** (10 damage): Light shake (strength ~4.0, duration ~0.16s)
- **Fast fall attack** (25 damage): Medium shake (strength ~7.5, duration ~0.25s)  
- **Maximum damage** (50+ damage): Heavy shake (strength 15.0, duration 0.4s)

### Attack Combinations:
- **Ground attack**: Normal shake feedback
- **Air attack + fast fall**: Enhanced shake due to damage multiplier
- **Downward air attack while fast falling**: Maximum shake for devastating attacks

## Testing

To test the camera shake system:

1. **Basic Testing**: Attack the test dummy with normal attacks to see light shake
2. **Fast Fall Testing**: Jump high, hold crouch to fast fall, then attack for stronger shake
3. **Damage Scaling**: Try different attack combinations to see shake intensity vary
4. **Duration Testing**: Notice how longer/stronger shakes accompany higher damage

## Technical Notes

### Camera Hierarchy:
- The system finds cameras using groups ("game_camera" and player camera)
- Both cameras shake simultaneously for consistent feel
- Gracefully handles missing cameras

### Performance:
- Uses efficient Tween animations
- Parallel tweens prevent blocking
- Automatic cleanup when animation completes

### Customization:
- Easy to adjust shake parameters
- Can be extended for other feedback (spell effects, explosions, etc.)
- Modular design allows easy integration with other systems

## Integration with Existing Systems

### Fast Fall Damage:
- Camera shake automatically scales with fast fall damage multipliers
- Creates satisfying feedback for high-speed attacks
- Encourages aggressive aerial combat

### Damage Particles:
- Works alongside existing damage number system
- Both systems trigger from the same damage event
- Creates comprehensive combat feedback

### Head Bonk Mechanic:
- Head bonk now uses the new shake system instead of basic shake
- Provides consistent shake feel across all game mechanics

## Future Extensions

The system can be easily extended for:
- Different shake patterns for different attack types
- Environmental damage feedback (explosions, collisions)
- UI feedback integration
- Screen effects and visual distortion
- Sound integration with damage feedback
