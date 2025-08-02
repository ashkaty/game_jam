# Jump Buffering Implementation

## Overview
Jump buffering allows players to press the jump button slightly before they can actually jump, making the game feel more responsive and forgiving. The system remembers the jump input for a short time window and executes the jump as soon as it becomes possible.

## How It Works

### Core System (in `player.gd`)
- **Jump Buffer Duration**: `jump_buffer_duration` (default: 0.15 seconds)
- **Buffer Timer**: `jump_buffer_timer` - counts down from the buffer duration
- **Buffer State**: `has_buffered_jump` - tracks if there's a buffered jump waiting

### Key Functions
- `buffer_jump()` - Called when jump is pressed but not possible
- `has_valid_jump_buffer()` - Checks if there's a valid buffered jump
- `consume_jump_buffer()` - Clears the buffer when a jump is executed

### Buffer Logic Flow
1. Player presses jump button
2. If `can_jump()` returns true → Execute jump immediately
3. If `can_jump()` returns false → Call `buffer_jump()` to store the input
4. Every frame, states check if `has_valid_jump_buffer() && can_jump()`
5. If both conditions are met → Execute the buffered jump and call `consume_jump_buffer()`

## States with Jump Buffering

### Ground States
- **Idle State**: Buffers jump input when jump cooldown is active
- **Move State**: Buffers jump input when jump cooldown is active  
- **Crouch State**: Buffers jump input since jumping isn't allowed while crouching

### Air States
- **Fall State**: Buffers jump input when no coyote time is available and not wall sliding

### When Buffering Triggers
Common scenarios where jump buffering helps:

1. **Landing Recovery**: Player presses jump right before landing, jump executes immediately upon landing
2. **Crouch to Jump**: Player presses jump while crouching, jump executes when crouch is released
3. **Jump Cooldown**: Player presses jump during the brief cooldown after landing, jump executes when cooldown ends
4. **Air Attempts**: Player presses jump while falling without coyote time, jump executes if they land within the buffer window

## Technical Details

### Buffer Duration Tuning
- **0.15 seconds** is the default - feels responsive without being too forgiving
- Shorter values (0.1s) feel tighter but less forgiving
- Longer values (0.2s+) can feel too automatic

### Integration with Existing Systems
The jump buffering system works alongside:
- **Coyote Time**: Buffered jumps can trigger coyote jumps if available
- **Jump Cooldown**: Buffer respects the jump cooldown system
- **Wall Jumping**: Wall jumps take priority over buffered regular jumps

### Debug Output
The system includes console output for debugging:
- "Jump buffered! Timer: X" - when a jump is buffered
- "Jump buffer expired" - when the buffer timer runs out
- "Executing buffered jump from [state]!" - when a buffered jump is executed
- "Jump buffer consumed!" - when the buffer is cleared

## Benefits for Players
- **More responsive controls**: Don't need perfect timing
- **Reduces frustration**: Failed jumps due to timing feel less punishing
- **Better flow**: Maintains momentum during fast-paced gameplay
- **Accessibility**: Helps players with timing difficulties

## Configuration
You can adjust the buffer duration in the editor by modifying the `jump_buffer_duration` property on the Player node. The default value of 0.15 seconds works well for most platformers.
