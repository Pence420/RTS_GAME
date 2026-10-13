# Tactical AI and game typography

## Approved direction

Replace the default UI typography with a more personal medieval presentation. Improve both armies' tactical decisions while keeping the player's explicit orders authoritative. The user approved the Taktis direction on 2026-10-13.

## Typography

The local project theme uses Alegreya Sans Medium for interface text and a weight-600 Alegreya variation for headings. Title/menu copy uses sentence case. HUD status and army totals have slightly larger sizes for a 1152x648 laptop window. The two unmodified font files and their SIL Open Font Licenses are bundled in assets/fonts; see that folder's README for official sources.

Main menu, battlefield HUD, and pause/army menu were rendered and inspected at 1152x648. Existing icon orders remain the primary interaction.

## Soldier decisions (both teams)

- Score candidates using distance, existing damage matchups, target congestion, and wounded opponents.
- Melee soldiers favor enemies already at contact. They also favor intercepting melee threats within 100 world units of a friendly archer or general.
- Preserve an engaged fight. Reconsider an unengaged chase every 0.4 seconds only when a candidate improves the score by more than 40 units.
- Advance and autonomous enemy orders regroup soldiers more than 155 units from their squad centre; they resume pursuit within 110 units. Explicit player Focus and Charge allow pursuit without that leash.
- Archers recognize melee threats within 90 units and keep retreating until their retained threat is at least 120 units away. Nearby additional threats influence the escape direction; field bounds and body collisions still apply. Other archers do not trigger melee panic.
- Fixed an existing movement bug: the attack branch reset an archer's speed every physics frame while firing and retreating, preventing acceleration. Retreat now preserves velocity and marks actual movement as chasing.

Manual movement runs before tactical decisions. Hold and Defend do not retreat or chase. Focus candidate lists remain restricted to the selected enemy squad. Routing retains its existing morale rules.

## Enemy army decisions

Every second the enemy commander scores surviving, nonrouting squads using distance, damage matchups, wounded targets, current friendly assignments, and threats near friendly archers. A target assignment adds a 75-unit score penalty to discourage sending every squad to one opponent. Commitments last 2.5 seconds; reassignment after that requires an improvement greater than 65 score units. Invalid targets are replaced immediately.

The enemy general follows 125 units behind the infantry centre, relative to the opposing army. Nearby melee danger can instead trigger an escape move. The player still positions their own general; friendly soldiers can prioritize its immediate threats.

## Evidence

The new tactical smoke first reproduced purely nearest-target choices, then exposed the retreat acceleration bug. It now verifies role choices on both teams, explicit focus restriction, archer threat classification and retreat, ally protection, cohesion, manual/Hold priority, and army target distribution.

All 23 Godot test scripts pass, including collision/formations, input, menu, casualty retargeting, routing, natural battle completion, a playable winning coordinated charge, and 12 interaction stress scenarios (2 victories, 10 defeats in this run).

These are deterministic tactical heuristics, not machine learning or an external AI service. Terrain is still visual scenery without cover/pathfinding. This pass changes decisions rather than combat stats; better targeting and faster retreat can change balance and battle outcomes. It does not add automatic formations, global flanking routes, or a new difficulty system.
