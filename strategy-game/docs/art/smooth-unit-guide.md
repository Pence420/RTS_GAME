# Smooth battle unit guide

The ten role and team atlases are original matte redraws for the smooth 2D battlefield. They replace the glossy interim chibi sheets while preserving every battle animation and team identity.

- Keep the shared three-quarter view, oversized helmet, compact body, and fixed boot position.
- Show each role through one large prop: shield and sword, long spear, broad axe, bow, or command banner.
- Use blue or red cloth and shields for team recognition; steel and leather stay neutral.
- Keep all 12 poses on a transparent 1254 × 1254 sheet. The game uses three frames for each idle, walk, and attack animation. Some attack frames repeat a clean pose where a weapon overlaps the next atlas cell. Keep the foot baseline stable inside the regions defined in `unit_visuals.gd`.
- Render with linear filtering. At default zoom, silhouette and team color matter more than costume detail.
- Future repainting should keep the matte metal and cloth, soft edges, and restrained highlights that match the terrain.
