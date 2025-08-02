# Multi-Track Timer System

## Overview
The cassette UI now supports independent timers for each of the 4 tracks (buttons). Each track maintains its own timer state, allowing you to switch between tracks while preserving the countdown progress for each track.

## How It Works

### Track System
- **Track 1 (Red Button)**: Independent timer
- **Track 2 (Yellow Button)**: Independent timer  
- **Track 3 (Blue Button)**: Independent timer
- **Track 4 (Green Button)**: Independent timer

### Timer Behavior
1. **Starting State**: All tracks start with 60 seconds by default
2. **Track Switching**: When you press a different button/key, the current track's timer is paused and saved
3. **Resume Timer**: Switching back to a previous track resumes from where it left off
4. **Track Completion**: When a track's timer reaches 0, it stays at 0 until manually reset

### Controls
- **Key 1**: Switch to Track 1 (Red) and drop red button
- **Key 2**: Switch to Track 2 (Yellow) and drop yellow button
- **Key 3**: Switch to Track 3 (Blue) and drop blue button
- **Key 4**: Switch to Track 4 (Green) and drop green button
- **TAB**: Toggle UI visibility

### Display
The timer now shows: `Track X - MM:SS` where X is the current track number.

## Programming Interface

### New Functions
```gdscript
# Track Management
switch_to_track(track_number: int)  # Switch to specific track (1-4)
get_current_track() -> int          # Get currently active track
get_track_time_remaining(track_number: int) -> float  # Get time for specific track
get_all_track_times() -> Dictionary  # Get all track times

# Track Timer Control
set_track_time(track_number: int, new_time: float)  # Set time for specific track
reset_track_timer(track_number: int)    # Reset specific track to default time
reset_all_track_timers()               # Reset all tracks to default time

# Animation with Track Switching
animate_red_button()    # Switch to track 1 and animate red button
animate_yellow_button() # Switch to track 2 and animate yellow button
animate_blue_button()   # Switch to track 3 and animate blue button
animate_green_button()  # Switch to track 4 and animate green button
```

### New Signals
```gdscript
signal track_timer_finished(track_number: int)  # Emitted when a specific track timer reaches 0
```

### Usage Example
```gdscript
# Switch to track 2
cassette_ui.switch_to_track(2)

# Check how much time is left on track 3
var track3_time = cassette_ui.get_track_time_remaining(3)

# Reset track 1 to full time
cassette_ui.reset_track_timer(1)

# Get all track times for saving
var all_times = cassette_ui.get_all_track_times()
```

## Implementation Details

### Data Storage
- `track_timers`: Dictionary storing time remaining for each track
- `current_track`: Currently active track number (1-4)
- `default_track_time`: Default time for new/reset tracks (60 seconds)

### Timer Persistence
- When switching tracks, current progress is automatically saved
- Track timers persist until manually reset or game restart
- Completed tracks (timer = 0) stay completed until reset

### Visual Feedback
- Only one button can be "down" at a time (mutually exclusive)
- Timer display shows current track number
- Progress bar reflects current track's progress
- Button animations provide immediate feedback when switching

## Benefits
1. **Multi-tasking**: Work on different tracks without losing progress
2. **Flexible Workflow**: Jump between tracks as needed
3. **Progress Persistence**: Never lose your timing progress
4. **Clear Feedback**: Always know which track is active
5. **Individual Control**: Each track can be managed independently
