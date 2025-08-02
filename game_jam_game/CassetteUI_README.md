# Cassette UI Element

## Overview
The Cassette UI Element is a retro-styled information display that shows player stats and other game information. It's designed to look like a cassette tape interface, providing a nostalgic aesthetic to your game.

## Features
- **Player Stats Display**: Shows health, score, level, and experience
- **Retro Cassette Design**: Uses the provided cassette UI asset for visual appeal
- **Customizable Information**: Can display custom messages and information
- **Toggle Functionality**: Press TAB to show/hide the UI
- **Real-time Updates**: Automatically updates player information when displayed

## Controls
- **TAB**: Toggle the Cassette UI on/off
- **× Button**: Close the UI (same as TAB)

## Usage in Game
The Cassette UI automatically connects to the player and displays:
- **Health**: Current health / Maximum health
- **Score**: Current player score
- **Level**: Current player level
- **Custom Info**: Any additional information set by the game

## Testing the Implementation
Once implemented, you can test the Cassette UI with these controls:
- **Attack** (Enter/Shift): Adds 10 points to score
- **Crouch** (S): Damages player by 5 health points
- **Up** (W): Heals player by 10 health points  
- **Jump** (Space): Adds 25 experience points

## Integration
The Cassette UI is already integrated into your main game scene (`game.tscn`) and will automatically:
1. Find the player in the scene
2. Connect to player stats
3. Update in real-time when visible
4. Respond to the TAB key for toggling

## Files Created/Modified
- `scenes/cassette_ui.tscn` - The main UI scene
- `scripts/cassette_ui.gd` - UI logic and functionality
- `scripts/game_manager.gd` - Game coordination script
- `scripts/player.gd` - Enhanced with stat tracking
- `assets/sprites/cassette_ui.png` - The cassette visual asset
- `assets/fonts/Jersey15-Regular.ttf` - Retro font for text display

## Customization
You can customize the Cassette UI by:
- Modifying the `cassette_ui.gd` script to change behavior
- Updating the visual design in `cassette_ui.tscn`
- Adding new information fields or changing the display format
- Changing the toggle key by modifying the input map in `project.godot`

The UI is designed to be modular and easy to extend with additional functionality as needed for your game.
