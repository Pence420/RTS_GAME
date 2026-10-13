# Smooth battle unit guide

The ten role and team atlases are original matte redraws for the smooth 2D battlefield. They replace the glossy interim chibi sheets while preserving every battle animation and team identity.

- Keep the shared three-quarter view, oversized helmet, compact body, and fixed boot position.
- Show each role through one large prop: shield and sword, long spear, broad axe, bow, or command banner.
- Use blue or red cloth and shields for team recognition; steel and leather stay neutral.
- Keep all 12 poses on a transparent 1254 × 1254 sheet. Walking and attacking use three frames. The idle poses currently shift limbs and weapons too much for a stationary stance, so runtime idle holds the clean first pose and adds subtle breathing with a fixed boot anchor. Some attack frames repeat a clean pose where a weapon overlaps the next atlas cell. Keep the foot baseline stable inside the regions defined in `unit_visuals.gd`.
- Render with linear filtering. At default zoom, silhouette and team color matter more than costume detail.
- Future repainting should keep the matte metal and cloth, soft edges, and restrained highlights that match the terrain.

Runtime motion follows actual velocity, including facing and walk cadence. Explicit movement takes priority over autonomous attacks and retreats; final steps stop exactly at the destination even on a slow physics tick. Valid nearby combat targets are retained until they leave range, die, or route, preventing small nearest-distance changes from reversing a chase. Walking accelerates briefly from rest without changing the unit's maximum speed.

Battle orders use native SVG icons with named tooltips. Keep formation, command, and touchpad symbols distinct and their click targets at least 44 × 44 UI pixels.
