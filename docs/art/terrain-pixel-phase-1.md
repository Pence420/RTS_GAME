# Pixel battlefield terrain — phase 1

## Approved direction

The user supplied a Tiny Swords reference and approved a broad 2D battlefield
with readable grass edges, rocky cliff faces, water, and cohesive scenery.
Small MiniFolks-style soldiers are the intended next unit direction. This
phase implements the terrain, retaining the current soldier sprites.

## Implementation

- Actual Tiny Swords legacy CC0 PNG assets, copied unmodified from the
  creator's `TS_old version_CC0 Licensed` archive. Provenance and original
  paths are recorded in `strategy-game/assets/terrain/tiny_swords_cc0/LICENSE.md`.
- Cached 64px atlas tile placement forms one connected central plateau,
  stepped coastal headlands, northern raised shelves, and small offshore islets.
- Exposed southern edges have visible stone faces. Earth tiles form a
  connecting lane across the battle area. Grass receives a restrained tint.
- Eight authored foam frames animate the coastline at 10fps; six tree
  frames supply wind without moving trunks or rotating pixel edges.
- Individual props share the soldiers' Y-sort layer and foot anchors.
  Nearest filtering preserves the pixel art; PNG imports remain lossless.
- Camera view bounds extend beyond the command bounds to reveal the
  coastline, while zoom and pan remain available. Starting zoom is 0.42.

## Gameplay and limits

The playable rectangle remains 2400x1400 with the existing 64px unit margin.
Every point within that margin is land. Deployment zones, unit collision,
orders, combat statistics, AI, and squad formations retain their behavior.
Trees stay outside the playable rectangle, including their crowns. Scenery
has no navigation obstacles. Raised shelves and offshore islands are visual
backdrop outside the command bounds; units cannot be placed there.

The title screen keeps its existing background in this phase. The soldier
sprite replacement is a separate phase.

## Verification

All 25 existing Godot smoke/stress scripts pass. The terrain regression now
checks walkable coverage throughout the playable rectangle, real tile and
animation sources, prop roots on land, crown clearance, pixel filtering,
Y-sort, and cleanup after restart. Camera tests use the expanded view bounds;
unit movement tests still use the original command bounds.

Rendered previews were inspected at initial, overview, and combat zooms.

## Follow-up

The MiniFolks unit phase was completed on 2026-10-14; see
`docs/art/minifolks-units.md`. The terrain described above remains in use.
