# Four Unit Types Implementation Plan

**Goal:** Add Swordsman, Spearman, Axeman, and Archer squads to both armies so each unit type has a distinct combat role and a full battle remains playable.

**Architecture:** `BattleUnit` owns per-type combat stats, attack behavior, and weapon drawing. `BattleSquad` assigns one type to its soldiers. `battle.gd` composes four ten-soldier squads per side and displays their type. Existing command, morale, General, AI, and result flows remain shared.

**Tech Stack:** Godot 4.7.1, GDScript, SceneTree smoke tests.

**Spec:** `/Users/joshuats/CodexGameGodot/PRD — 2D Pixel Tactical Battle Simulator.md`, sections 3–5, 7–8, 13, 19, and 24.

## Global Constraints

- One battlefield with 20–40 soldiers per army.
- Four unit types: Swordsman, Spearman, Axeman, Archer.
- Archer attacks from range and keeps distance from melee attackers.
- Existing squad commands, formations, morale, AI, and result screen continue to work.
- Placeholder visual shapes are acceptable.

## Review Focus

- An Archer ordered to Hold must fire in range without chasing.
- An Archer close to melee enemies must retreat while staying inside the battlefield.
- A focused target that dies must be replaced by a surviving target.
- Squad health and unit counts must still update after casualties among different unit types.
- Either army losing all four squads must still end the battle and permit restart.

### Task 1: Unit profiles and attacks

**Files:** `scripts/unit.gd`; `tests/unit_types_smoke.gd`.

- [x] Add a unit type enum and a configuration method assigning HP, damage, armor, attack range, attack interval, and move speed. Preserve the existing Swordsman defaults and General override.
- [x] Use configured attack range and interval for targeting and combat. Add a simple counter modifier for Axeman against Swordsman and Spearman while defending.
- [x] Let Archer attack at range and retreat from nearby melee enemies within the map bounds. Draw a short shot trace during a hit.
- [x] Draw type-specific weapon cues using existing placeholder shapes.
- [x] Verify type stats, ranged damage, Hold behavior, retreat bounds, and counter damage in a SceneTree smoke test.

### Task 2: Typed squads and armies

**Files:** `scripts/squad.gd`; `scripts/battle.gd`; `tests/unit_types_smoke.gd`.

- [x] Give each squad a type and configure each spawned soldier before it enters the tree.
- [x] Spawn four squads of ten per army, one of each type, on the current battlefield.
- [x] Show the selected squad's type in the status label.
- [x] Verify 40 soldiers per side and that all types can be selected and ordered.

### Task 3: Regression and balance

**Files:** Existing `tests/*.gd`, with focused assertion updates where the army size or unit stats changed.

- [x] Run every SceneTree test using Godot headless and update obsolete two-squad and homogeneous-stat assumptions.
- [x] Run natural and commanded battles to confirm a reachable Victory and Defeat.
- [x] Run interaction stress tests and resolve any engine errors or stuck battles.
- [x] Launch the project and verify the deployment view, a complete natural battle, and Play Again.

The project directory has no Git metadata, so this plan cannot be committed here.
