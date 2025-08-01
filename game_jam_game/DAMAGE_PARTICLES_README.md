# Damage Particles System

This system creates red floating damage numbers when the player deals damage to enemies.

## Components

### DamageParticle (`damage_particle.gd`)
- A Label-based particle that displays damage numbers
- Features:
  - Red text with black shadow for visibility
  - Floats upward with slight random horizontal movement
  - Fades out over time
  - Scales up slightly at spawn, then shrinks
  - Auto-destroys after 2 seconds

### DamageParticleManager (`damage_particle_manager.gd`)
- Singleton-style manager that spawns damage particles
- Added to the main game scene as a node
- Provides static method `spawn_damage_text(damage_amount, world_position)` for easy access

### DamageParticle Scene (`damage_particle.tscn`)
- Simple Label node with the DamageParticle script attached
- Centered anchoring for proper positioning

## Integration

The system is integrated into the existing damage system through the `HurtBox` class:
- When damage is taken, a damage particle is automatically spawned at the hit location
- No additional code needed in individual enemies - just ensure they have a HurtBox

## Usage

To spawn damage particles manually from anywhere in the code:
```gdscript
DamageParticleManager.spawn_damage_text(25, Vector2(100, 100))
```

## Customization

You can modify the following properties in `DamageParticle`:
- `float_speed`: How fast the particle floats upward
- `fade_speed`: How quickly it fades out  
- `lifetime`: How long the particle exists
- Font size, colors, and shadow in the `_ready()` method
