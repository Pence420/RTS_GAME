# Readable battle presentation

The player approved a compact interface based on the attached medieval battlefield reference. Keep the current smooth chibi artwork, provide breathing room between idle soldiers, add restrained blood on death, and give the battlefield more screen space. Continue with the previously chosen native execution method.

## Presentation

Use a 0.18 sprite scale and 42 × 50 world-pixel slot spacing, compared with the previous 0.22 scale and 32 × 36 spacing. Stagger idle animation phases deterministically between soldiers. Keep formation bonuses and unit statistics intact. Clamp squad movement using the current slot extents so every destination stays inside the field. Space the four initial squad lanes symmetrically at y = 260, 400, 540, 690; preserve their existing x coordinates. Center the camera at (800, 450).

## Interface

A narrow centered olive frame at the top contains blue/red strength bars and remaining soldier counts. Keep deployment state, Start Battle, and Menu accessible. A centered bottom frame contains General and four squad portrait buttons, a compact two-line selection summary, Orders, and zoom buttons. Portrait tooltips identify squad type, health, and morale. Orders opens the existing formation, command, and alternative touchpad actions in a tray above the dock. The tray starts closed. Clicking HUD controls must never issue a world order or pan the camera. Dead portraits disable without changing the identity of remaining squad buttons.

## Death feedback

Draw a small irregular dark red ground stain and several ballistic droplets. The splash lasts less than half a second; the stain fades after a few seconds. Briefly show the existing chibi sprite falling and fading. Effects belong to the battle ground layer so they survive removal of a squad's final soldier and draw below living units. No damage, morale, target, or battle-result rule changes.

## Validation

Measure opaque idle silhouette overlap across all roles, teams, and frames: adjacent soldiers in the default formation must overlap by no more than 10%. Check deployment at 1152 × 648 and larger windows, with all squads visible above the dock. Exercise squad and General selection, Orders open/close, focus targeting, hold-and-drag movement, empty-ground panning, zoom, last-soldier death, and automatic effect cleanup. Run existing gameplay smoke tests and inspect rendered deployment and combat screenshots.
