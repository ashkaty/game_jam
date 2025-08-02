# Cassette Buttonless UI

This updated cassette UI features the new "Cassette Buttonless" asset with interactive colored buttons that animate when corresponding number keys are pressed.

## Features

- **New Background**: Uses the "Cassette Buttonless.png" asset instead of "Cassette UI Element 2.png"
- **Interactive Buttons**: Four colored buttons (Red, Yellow, Blue, Green) that animate on key press
- **Button Animation**: Buttons move down and back up when activated
- **Number Key Controls**: Press keys 1-4 to trigger button animations
  - **1 Key**: Animates Red Button
  - **2 Key**: Animates Yellow Button  
  - **3 Key**: Animates Blue Button
  - **4 Key**: Animates Green Button

## Implementation Details

### Scene Structure
- **Background**: Uses NinePatchRect with Cassette Buttonless texture
- **ButtonContainer**: Contains all four animated buttons positioned on top of the cassette
- **Button Layout**: Small buttons (20x20 pixels) positioned horizontally across the top of the cassette player

### Script Features
- **Button Position Storage**: Stores original positions for animation reset
- **Tween Animation**: Smooth down/up animation with reduced offset (5px) for smaller buttons
- **Input Handling**: Listens for number key inputs when UI is visible
- **Public Methods**: External scripts can trigger button animations
- **Async Initialization**: Waits for proper node initialization before storing button positions

### Usage
```gdscript
# Trigger button animations from external scripts
cassette_ui.animate_red_button()
cassette_ui.animate_yellow_button()
cassette_ui.animate_blue_button()
cassette_ui.animate_green_button()
```

## Controls
- **TAB**: Toggle UI visibility
- **1-4**: Animate corresponding colored buttons
- **×**: Close button to hide UI

## Files Modified
- `scenes/cassette_ui_v2.tscn` - Updated scene with new assets and button layout
- `scripts/cassette_ui_v2.gd` - Added button animation functionality
- Added new sprite assets and import files for all button textures
