# Smooth battle unit guide

The ten role and team atlases reuse the project's original smooth chibi artwork from commit `b6c24ec`. This restores antialiased silhouettes in place of the later pixel versions while keeping every existing battle animation and team identity.

- Keep the shared three-quarter view, oversized helmet, compact body, and fixed boot position.
- Show each role through one large prop: shield and sword, long spear, broad axe, bow, or command banner.
- Use blue or red cloth and shields for team recognition; steel and leather stay neutral.
- Keep all 12 poses on a transparent 1254 × 1254 sheet. The game uses three poses from each idle, walk, and attack row.
- Render with linear filtering. At default zoom, silhouette and team color matter more than costume detail.
- Future repainting should use matte metal and cloth, soft edges, and restrained highlights to match the terrain.
