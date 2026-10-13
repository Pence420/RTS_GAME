# RTS_GAME

A fully 2D medieval tactical battle game built in Godot. Open `strategy-game/project.godot` to run it.

## Battlefield controls

- **Left-click:** select a squad or general.
- **Right-click ground:** move. **Double right-click:** run. On a Mac touchpad, Control + click works too.
- **Right-click an enemy:** attack. **Double right-click:** charge.
- **Defend:** guard the formation and counter nearby enemies.
- **Full Attack:** aggressive pursuit and charges.
- Click the active stance again to return to automatic guarding.
- Drag the selected unit to reposition; drag empty ground to pan.
- The orders tray contains formations and touchpad alternatives. Use `+` / `−` or scroll to zoom.

The map is 2400×1400. Before battle, the blue outline marks your deployment area; after Start, troops can move across the battlefield.

Terrain uses legacy CC0 Tiny Swords sprites: grass, earth lanes, rocky coastal cliffs, animated shoreline foam, and trees with authored wind frames. Zoom out to see the coastline. See `docs/art/terrain-pixel-phase-1.md` for scope and asset provenance.

Without an explicit order, player soldiers guard their position and fight nearby threats. See `docs/gameplay/direct-orders-and-stances.md` for details.

Units use original MiniFolks Humans sprites by LYASeeK, with authored idle/walk/attack/death animations and blue/red cloth palettes. Axeman uses the pack’s halberd character. See `docs/art/minifolks-units.md` for role mappings and license terms.
