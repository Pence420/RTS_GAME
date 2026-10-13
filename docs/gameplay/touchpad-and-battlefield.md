# Touchpad context orders and expanded battlefield

## Report and diagnosis

The user reported that both secondary two-finger clicks and Control-click failed, requested more battlefield/placement space, and asked for external sprite inspiration.

A real viewport-dispatch regression reproduced two concrete defects:

- Control + left click followed the primary selection/drag path instead of giving a context order.
- A click on a soldier's visible upper sprite could miss its small foot-centred pick radius, preventing selection before the next order.

Ordinary secondary-button input passed the software repro. The previous direct handler test bypassed GUI dispatch and did not exercise either defect. GUI swallowing remained a possible surface-specific cause, so context orders now run in the early input path with the existing explicit HUD/overlay guards.

## Fix

- Normalize right-click and Control + left click in `_input` before GUI/unhandled dispatch.
- Consume context press/release on the battlefield and cancel primary drags. Retain the initiating button so a Control-click release is still recognized after Control is released.
- Keep UI panels and battle/result menus protected from world orders.
- Pick the character's used sprite rectangle, including flip and scale, with a ground-distance tie-break where silhouettes overlap. Physics collision remains the radius-16 foot body.

## Map and deployment

`battle_field.gd` defines the shared 2400×1400 field, a 64-unit playable margin, blue/red deployment areas with a 120-unit neutral gap, and the starting-position offset. Terrain, camera, movement constraints, routing exits, and drag previews consume those definitions.

Both armies and the starting camera shift by (400, 250), preserving the opening skirmish distances and readable unit scale. Ground tiles, road, patches and edge props cover the larger field without enlarging individual characters or prop sprites. Minimum camera zoom is 0.45, still constrained by viewport width to avoid showing outside the ground.

The blue placement area is outlined and lightly tinted before battle. Whole formation slots are clamped inside their deployment area. On Start, both armies can use the full playable field. The old hidden squad rectangle (x160–1440, y170–730) is removed. Drag preview and issued movement use the same formation clamp.

## Verification

- `trackpad_input_smoke.gd`: real viewport event dispatch for visible-head selection, secondary click, Control-click with early modifier release, and attacking a visible enemy sprite.
- Native macOS window clicks were also verified: a secondary click set Blue A's goal to (1042.5, 677.5); Control-click set it to (917.5, 690), preserving selection without starting a primary drag. These verify the native button/modifier paths, rather than physically generating a two-finger gesture.
- `battlefield_bounds_smoke.gd`: shared map size, all four formation destinations at both deployment extremes, general deployment limits, movement to (2200,1250) after Start, and camera edges.
- All 25 test scripts pass. Morale escape timing now derives from route distance instead of assuming the smaller field's three-second trip. The winning player-strategy fixture keeps the General's rally aura near advancing infantry; its victory assertion is retained. The 12 interaction stress scenarios and natural battle still complete.
- Deployment, map overview, and removal of deployment tint after Start were rendered at 1152×648 and visually inspected.

No operating-system touchpad settings were changed. New sprite packs were researched as references; none were installed or substituted into the current game.
