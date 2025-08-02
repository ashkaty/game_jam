# Game Timer Implementation

## Overview
A 1-minute countdown timer has been implemented in the CassetteButtonlessUI that starts automatically when the game begins.

## Features
- **Countdown Timer**: Displays time in MM:SS format (e.g., "01:00", "00:30", "00:00")
- **Auto-Start**: Timer begins counting down automatically when the game starts
- **Signal Integration**: Emits `timer_finished` signal when countdown reaches zero
- **Game Manager Integration**: Game manager responds to timer completion

## Implementation Details

### Files Modified
1. **scripts/cassette_buttonless_ui.gd**
   - Added TimerLabel reference: `@onready var timer_label: Label = $TimerContainer/TimerLabel`
   - Added timer variables for countdown management
   - Added timer functions for start, stop, reset, and display updates
   - Integrated timer updates in `_process()` function
   - Added `timer_finished` signal

2. **scripts/game_manager.gd**
   - Connected to `timer_finished` signal from cassette UI
   - Added `_on_timer_finished()` callback function for game-ending logic

### Timer Variables
- `countdown_time: float = 60.0` - Initial countdown time (1 minute)
- `time_remaining: float = 60.0` - Current remaining time
- `is_timer_running: bool = false` - Timer state flag

### Timer Functions
- `start_timer()` - Begins the countdown
- `_update_timer_display()` - Updates the label with current time
- `get_time_remaining()` - Returns remaining seconds
- `is_timer_active()` - Checks if timer is running
- `stop_timer()` - Stops the countdown
- `reset_timer()` - Resets to initial time
- `set_countdown_time(new_time)` - Changes countdown duration

### Display Format
The timer displays in MM:SS format:
- `01:00` - 1 minute remaining
- `00:30` - 30 seconds remaining
- `00:05` - 5 seconds remaining
- `00:00` - Timer finished

## Usage
The timer starts automatically when the game begins. When it reaches zero:
1. Timer stops counting
2. `timer_finished` signal is emitted
3. Game manager receives the signal via `_on_timer_finished()`
4. Custom game-ending logic can be added to the callback

## Customization
To change the countdown time, modify the `countdown_time` variable in the `_ready()` function or call `set_countdown_time(new_time)` before starting the timer.

## Testing
Run the game to see the timer counting down from 01:00 to 00:00 in the top-left area of the cassette UI.
