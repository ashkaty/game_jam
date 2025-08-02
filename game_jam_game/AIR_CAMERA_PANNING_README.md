# Air Camera Panning System

This implementation adds automatic camera panning when the player is in the air, providing better visibility of the area below for improved landing and aerial combat.

## How It Works

### Core Mechanic
- When the player is airborne (jumping or falling), the camera automatically pans down after a short delay
- This gives players better visibility of platforms, enemies, and landing spots below
- The camera smoothly returns to normal position when landing

### Key Features

1. **Automatic Air Detection**: Camera pans down when in jump or fall states
2. **Delayed Activation**: Small delay before panning starts to avoid disorientation
3. **Smooth Transitions**: Gradual camera movement for natural feel
4. **Different Settings**: Jump and fall states have different panning amounts and delays
5. **Automatic Reset**: Camera returns to normal position when landing

## Configuration

### Fall State (fall.gd):
```gdscript
@export var air_camera_offset_y: float = 60.0           # How much camera moves down
@export var air_camera_transition_speed: float = 6.0    # Speed of camera movement
@export var air_camera_pan_delay: float = 0.2           # Delay before panning starts
```

### Jump State (jump.gd):
```gdscript
@export var air_camera_offset_y: float = 40.0           # Less panning during jumps
@export var air_camera_transition_speed: float = 6.0    # Speed of camera movement  
@export var air_camera_pan_delay: float = 0.3           # Longer delay for jumps
```

### Crouch State (crouch.gd):
```gdscript
@export var camera_offset_y: float = 80.0               # Enhanced crouching camera pan
```

## Implementation Details

### Files Modified:
1. **fall.gd**: Added air camera panning for falling
2. **jump.gd**: Added air camera panning for jumping
3. **crouch.gd**: Enhanced existing crouch camera panning

### Key Functions:
- `enter()`: Sets up camera target position and resets timer
- `exit()`: Restores original camera position
- `process_frame()`: Handles smooth camera transitions with delay

### State-Specific Behavior:
- **Jump State**: Less aggressive panning (40px) with longer delay (0.3s) for natural jumping feel
- **Fall State**: More panning (60px) with shorter delay (0.2s) for better falling visibility
- **Crouch State**: Maximum panning (80px) for enhanced fast-fall vision

## Usage Examples

### Air Visibility Improvements:
- **Jumping**: Camera gently pans down after 0.3 seconds to show landing areas
- **Falling**: Camera pans down more aggressively after 0.2 seconds for platform visibility
- **Fast Falling**: Combined with crouch camera panning for maximum downward view
- **Aerial Combat**: Better visibility for targeting enemies below during air attacks

### Integration with Existing Systems:
- **Fast Fall Mechanic**: Enhanced visibility while fast falling with crouch
- **Air Attacks**: Better targeting for downward strikes
- **Platform Navigation**: Easier to judge landing distances and platform placement
- **Combat Positioning**: Improved ability to position for aerial attacks

## Technical Notes

### Camera Management:
- Each air state manages its own camera offset independently
- Smooth transitions prevent jarring camera movements
- Original position is always restored when landing

### Performance:
- Uses efficient move_toward() for smooth interpolation
- Minimal overhead with simple timer-based activation
- No continuous calculations when not needed

### Timing Considerations:
- **Jump Delay (0.3s)**: Prevents disorientation during quick jumps
- **Fall Delay (0.2s)**: Faster activation for falling situations
- **Transition Speed**: Balanced for natural camera movement

## Benefits

### Gameplay Improvements:
1. **Better Landing Accuracy**: See platforms and landing spots clearly
2. **Enhanced Combat**: Improved targeting for downward attacks
3. **Reduced Frustration**: Less blind jumping and falling
4. **Strategic Awareness**: Better understanding of terrain below

### Visual Comfort:
1. **Smooth Transitions**: No jarring camera snaps
2. **Appropriate Delays**: Prevents motion sickness from instant panning
3. **State-Appropriate**: Different behavior for different air states
4. **Automatic Reset**: Always returns to normal view when landing

## Testing

To test the air camera panning:

1. **Basic Air Panning**: Jump and notice camera gradually pans down after 0.3s
2. **Fall Panning**: Walk off a platform and see faster camera panning after 0.2s
3. **Fast Fall**: Hold crouch while falling for maximum downward camera view
4. **Landing Reset**: Notice camera smoothly returns to normal when landing
5. **State Transitions**: Test jumping -> falling -> landing camera behavior

The system provides a much more intuitive aerial experience with improved visibility for all air-based gameplay!
