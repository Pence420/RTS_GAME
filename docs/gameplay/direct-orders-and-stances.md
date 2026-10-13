# Direct orders and two combat stances

## User direction

Use direct battlefield controls inspired by Total War. Keep Defend and Full Attack buttons, plus formations. Soldiers must counter nearby enemies while guarding rather than standing idle under attack.

## Controls

- Left-click: select a squad or general.
- Right-click ground (Control + click also works on Mac): walk to the destination and cancel an earlier explicit attack.
- Double right-click ground: run, at 1.35 times the normal movement speed before formation/defence modifiers.
- Right-click an enemy squad or general: attack that target.
- Double right-click an enemy: charge it.
- Drag the selected squad/general: reposition. Drag empty ground: pan.
- Touchpad Move/Target alternatives and zoom buttons remain available.

The old Hold, Advance, and Focus Target buttons and their panel handlers were removed. The tray now exposes four formation icons, two stance icons, and three touchpad alternatives. Icon tooltips and the field guide describe the new controls.

The later expanded-field pass adds visible blue deployment limits and a 2400×1400 map. See touchpad-and-battlefield.md for input diagnosis and current bounds.

## Stances

Neither stance selected means automatic Guard. Player soldiers start in this state: they detect nearby enemies within 130 world units (or their longer ranged reach), pursue no farther than 95 units from individual guard anchors, and return when the threat leaves.

Defend retains the existing 20% damage reduction and 20% movement penalty. Melee detection is 90 units with a 60-unit pursuit leash. Ranged soldiers can fire to their existing range; Defend does not automatically retreat. A direct attack explicitly authorizes pursuit while retaining stance protection.

Full Attack enables aggressive acquisition and the existing charge behaviour. It preserves an explicit target when activated, and target selection through either right-click or the touchpad alternative uses Charge. It does not override a ground destination. Manual walking/running does not stack the charge pursuit speed bonus with the run speed bonus.

Stances and destinations are independent: changing stance preserves any currently assigned movement destinations and the walk/run choice. Clicking an already active stance toggles back to Guard. Formations keep their existing bonuses and body collision.

After completing a ground move, each soldier anchors at its actual arrival position. After an explicit target is eliminated, the player squad resumes its selected stance at its current position. Enemy squads retain their army planner.

General targets are tracked separately from squad targets. A selected general can also receive an explicit attack. Death signals clear both squad and general pursuit references.

## Verification

All 23 existing test scripts pass after updating command/UI expectations to the new controls. The direct-order regression covers a synthetic double right-click through the input handler, walk/run/attack, stance changes during movement, preservation of defensive protection during explicit attacks, charge target retention, cancellation by a ground move, soldier/general target selection and death cleanup, nearby defensive counterattack, the guard leash, and return to formation.

The 12 interaction stress scenarios now exercise stance toggles, run orders, direct attacks, touchpad alternatives, and formation changes (1 victory and 11 defeats in this run). Natural battle and the coordinated-charge winning strategy still complete. Collision, casualty retargeting, HUD, routing, animations, and menu checks also pass.

The stance tray, field guide, and guarding battle were rendered at 1152x648 and visually inspected. This is a local guarding policy and direct order system, not a replica of every Total War mechanic. Ground scenery is still decorative, and full navigation around solid terrain remains a separate feature.
