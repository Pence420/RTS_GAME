# MiniFolks Humans integration

Implemented 2026-10-14 following the user's requested MiniFolks character direction.

## Assets and roles

Actual unmodified `Outline/` sprites from LYASeeK's free MiniFolks Humans pack:
https://lyaseek.itch.io/minifhumans. The creator permits use and prohibits
reselling the assets. Provenance, archive checksum and terms are recorded in
`strategy-game/assets/units/minifolks/LICENSE.md`.

| Gameplay role | Original asset |
| --- | --- |
| Swordsman | MiniSwordMan |
| Spearman | MiniSpearMan |
| Axeman | MiniHalberdMan (poleaxe/halberd silhouette) |
| Archer | MiniArcherMan |
| General | MiniKingMan |

Axeman retains its combat stats and behavior. The free pack has a halberd
character rather than a short-axe character, so that is its visual mapping.
These source sprites face sideways; left/right flipping supplies facing.
This does not add an eight-direction animation set.

## Rendering and animation

- Original 32x32 cells, enlarged at integer scale 3 with nearest filtering.
- Four authored idle poses, five or six walk poses, full six-to-eleven-frame
  attack sequences, and four-to-six-frame deaths. Source animation rate 10fps.
- All source frames use a shared foot anchor. Idle poses play without scale
  breathing or simulated body rotation; movement in world space is unchanged.
- Attack animation can finish beyond the brief impact flash. Explicit movement
  interrupts it; timing of damage and combat cooldowns stays unchanged. Longer
  attack sequences fit the existing cooldown through visual speed scaling.
- Red faction material maps only the two cloth-blue palette entries. Original
  skin, outlines, steel and gold remain unchanged. Hit flashes still modulate.
- General/squad portraits use cropped MiniFolks frames and nearest filtering.
- Death effects play authored collapse frames with the matching team material,
  keeping the existing blood splatter, fade and cleanup.

## Verification

All 25 smoke/stress scripts pass, including unit collision, formation clearance,
input dispatch, combat, AI, portraits and death cleanup. Visual regressions check
all atlas cells, correct roles, palettes, complete attack presentation, authored
idle, foot anchoring, sprite selection and death playback.

A GL-rendered roster was inspected alongside battle and combat views. Pixel
counts confirmed the red palette changes only cloth, preserving the original
steel and skin pixels. Idle formation silhouette overlap measured 0%.
