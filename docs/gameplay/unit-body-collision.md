# Unit body collision and formation assembly

## Request

Give each soldier a physical body, prevent stacks during Column and other formation changes, and make moving and fighting crowds feel like a battlefield.

## Diagnosis

The unit scene used CharacterBody2D with collision layer/mask zero and no shape. Formation changes also sent soldiers to fixed numbered slots, producing crossed paths. Combat selected the nearest enemy independently for every soldier.

## Implementation phases completed

1. Enable native 2D swept body collision with a radius-16 circle at the feet, floating motion, and moving-platform behavior disabled.
2. Add local passing and a 36-unit personal-space buffer. Use actual displacement for locomotion. Settle near an occupied destination rather than walking forever. Resolve residual crowd contacts after all soldiers move, including teammates and enemies.
3. Match surviving soldiers to unique, centered formation slots by minimum total squared travel distance. Spread target selection over less crowded enemies and rescan a blocked chase. Retreat along a field boundary when necessary.

The formation assignment uses subset dynamic programming for at most ten soldiers (1024 subsets). The single shared contact solver performs at most twelve passes over nearby pairs. These limits suit the current 82-character battle; larger armies should use a spatial index and profiling before increasing the roster.

Damage, armor, attack cadence, formation bonuses, and ranged reach retain their existing values. Sword/axe/general centre-to-centre melee contact reach is now at least 35 world units so a 32-unit body pair can exchange attacks. Spearmen retain their longer 42-unit reach. Actual combat outcomes can change because soldiers occupy space.

## Verification

- Regression first reproduced soldiers passing through each other with collisions disabled.
- Collision smoke: opposing moves pass around bodies; occupied destination settles at contact; Line, Column, Shield Wall, and Wedge assemble without penetration and retain their ordered centre; two opposing squads reach melee contact without body overlap. Runs at 4x simulation speed, checking separation every physics frame.
- Existing formation assertions now check geometry rather than soldier identity, since assignment intentionally changes slot owners. The slow-frame movement fixture places its unrelated enemy outside the arrival destination.
- All 22 Godot scripts pass, including 12 interaction stress scenarios, natural battle completion, a winning coordinated charge, routing, casualty handling, input, HUD, animation, and terrain.
- Rendered deployment and combat at 1152x648, inspected formation spacing and crowd contact visually.

This provides local crowd movement, not global navigation around future solid scenery. Current environment props remain decorative.
