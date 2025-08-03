# Track Visibility System

## Overview
This system ensures that only one player is visible at a time based on the currently active track selected in the UI. The camera and UI focus on the player of the track that the player_manager has as active.

## How It Works

### Core Functionality
1. **Single Player Visibility**: Only the player on the currently active track is visible
2. **Camera Following**: The main camera follows the active player smoothly
3. **UI Synchronization**: The cassette UI buttons reflect the currently active track
4. **Seamless Switching**: When switching tracks, the visibility changes instantly and the camera transitions smoothly

### Key Features
- **Track 1 (Red Button)**: Shows and focuses on Player Track 0
- **Track 2 (Yellow Button)**: Shows and focuses on Player Track 1  
- **Track 3 (Blue Button)**: Shows and focuses on Player Track 2
- **Track 4 (Green Button)**: Shows and focuses on Player Track 3

## Implementation Details

### Files Modified
1. **player_manager.gd**: 
   - Added player visibility control
   - Added camera following system
   - Added UI integration
   - Added track switching coordination

2. **cassette_buttonless_ui.gd**:
   - Added player manager integration
   - Added track change signaling
   - Added display-only update methods
   - Prevented infinite switching loops

### Key Functions

#### PlayerManager
```gdscript
activate_track(idx: int)           # Switches active track and updates visibility
switch_to_track(track_index: int)  # Public method for track switching
get_active_player() -> Player      # Returns the currently active player
_update_camera_follow()            # Keeps camera following active player
```

#### CassetteButtonlessUI
```gdscript
switch_to_track(track_number: int)        # Switches track with full logic
update_track_display_only(track_number)  # Updates visuals without switching
track_changed signal                      # Emitted when track changes
```

## Usage

### Switching Tracks
- **Keyboard**: Press keys 1, 2, 3, or 4 to switch tracks
- **UI Buttons**: Click the colored buttons on the cassette UI
- **Programmatic**: Call `player_manager.switch_to_track(index)` or `cassette_ui.switch_to_track(number)`

### Camera Behavior
- Smoothly transitions between players when switching tracks (0.3 second transition)
- Continuously follows the active player during gameplay
- Individual player cameras are disabled to prevent conflicts

### Integration
- UI automatically reflects the active track with button states
- Timer system maintains separate timers for each track
- Health system works with the active player

## Technical Notes

### Player Positioning
- All players are positioned at Vector2.ZERO since only one is visible at a time
- This prevents camera positioning issues when switching tracks

### Loop Prevention
- Both UI and PlayerManager check for current track before switching
- Separate methods for display updates vs. full track switching
- Prevents infinite loops between UI and PlayerManager

### Camera Management
- Main camera in PlayerManager follows active player
- Individual player cameras are disabled
- Smooth transitions using Godot's Tween system

## Benefits
1. **Clear Focus**: Only one player visible reduces visual confusion
2. **Smooth Experience**: Camera transitions feel natural
3. **Consistent UI**: Button states always match active track
4. **Performance**: Only one player processes input at a time
5. **Intuitive Controls**: Natural track switching via number keys or UI

## Future Enhancements
- Add visual effects during track transitions
- Implement track preview system
- Add audio cues for track switching
- Support for custom track switching animations
