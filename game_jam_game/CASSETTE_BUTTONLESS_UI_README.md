# Cassette Buttonless UI

This updated cassette UI features the new "Cassette Buttonless" asset with interactive colored buttons that animate when corresponding number keys are pressed.

## Features

- **New Background**: Uses the "Cassette Buttonless.png" asset instead of "Cassette UI Element 2.png"
- **Interactive Buttons**: Four colored buttons (Red, Yellow, Blue, Green) that animate on key press
- **Track State System**: Current track (1-4) determines which button stays lowered
- **Button Animation**: Buttons move down and back up when activated, selected track button stays lowered
- **Number Key Controls**: Press keys 1-4 to set the track and trigger button animations
  - **1 Key**: Sets Track to 1 (Red Button lowered)
  - **2 Key**: Sets Track to 2 (Yellow Button lowered)  
  - **3 Key**: Sets Track to 3 (Blue Button lowered)
  - **4 Key**: Sets Track to 4 (Green Button lowered)

## Implementation Details

### Scene Structure
- **Background**: Uses NinePatchRect with Cassette Buttonless texture
- **ButtonContainer**: Contains all four animated buttons positioned on top of the cassette
- **Button Layout**: Small buttons (20x20 pixels) positioned horizontally across the top of the cassette player

### Script Features
- **Track State Management**: Tracks current selected track (1-4) and updates button positions accordingly
- **Button Position Storage**: Stores original positions for animation reset
- **Tween Animation**: Smooth down/up animation with reduced offset (5px) for smaller buttons
- **Selected Button Display**: Currently selected track button stays lowered by 8px
- **Input Handling**: Listens for number key inputs when UI is visible to set track state
- **Public Methods**: External scripts can trigger button animations and get/set track state
- **Async Initialization**: Waits for proper node initialization before storing button positions

### Usage
```gdscript
# Set track state (also triggers button animation)
cassette_ui.set_track(1)  # Red button lowered
cassette_ui.set_track(2)  # Yellow button lowered
cassette_ui.set_track(3)  # Blue button lowered
cassette_ui.set_track(4)  # Green button lowered

# Get current track information
var current_track = cassette_ui.get_track()  # Returns 1-4
var track_name = cassette_ui.get_track_name()  # Returns "Red", "Yellow", "Blue", or "Green"

# Trigger button animations without changing track
cassette_ui.press_red_button()
cassette_ui.press_yellow_button()
cassette_ui.press_blue_button()
cassette_ui.press_green_button()
```

## Controls
- **TAB**: Toggle UI visibility
- **1-4**: Animate corresponding colored buttons
- **×**: Close button to hide UI

## Files Modified
- `scenes/cassette_ui_v2.tscn` - Updated scene with new assets and button layout
- `scripts/cassette_ui_v2.gd` - Added button animation functionality
- Added new sprite assets and import files for all button textures
