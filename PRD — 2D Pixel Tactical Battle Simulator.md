# Product Requirements Document
## Project: 2D Pixel Tactical Battle Simulator

### 1. Project Overview

Game tactical battle simulator 2D berbasis pixel art yang terinspirasi dari sistem pertempuran seperti Total War, tetapi dengan scope kecil dan gameplay yang lebih sederhana.

Player berperan sebagai commander yang mengatur posisi pasukan, formasi, dan perintah sebelum serta selama battle.

Setelah battle dimulai, setiap unit akan bergerak dan bertarung secara semi-otomatis berdasarkan command, AI, jarak musuh, dan kondisi battlefield.

Game dibuat menggunakan **Godot Engine** dengan visual **top-down 2D pixel art**.

---

## 2. Core Gameplay Loop

1. Player masuk ke battlefield.
2. Player melihat pasukan sendiri dan musuh.
3. Player mengatur posisi awal squad.
4. Player memilih formation dan command.
5. Player menekan **Start Battle**.
6. Unit bergerak dan bertarung secara otomatis.
7. Player dapat memberikan command tambahan selama battle.
8. Battle selesai ketika salah satu army kalah atau seluruh unit kehilangan morale.

Flow:

**Deployment → Formation → Command → Battle → Victory / Defeat**

---

## 3. MVP Scope

MVP hanya memiliki:

- 1 battlefield
- Player Army vs AI Army
- 4 jenis combat unit
- 1 General
- Basic formation system
- Basic command system
- Basic combat system
- Morale system
- Simple enemy AI
- Victory / defeat condition

Target awal:

**20–40 soldiers per army.**

Tidak perlu campaign, economy, base building, multiplayer, inventory, atau world map.

---

# 4. Unit Types

## Swordsman

Role:

Standard melee infantry.

Characteristics:

- Medium HP
- Medium damage
- Medium armor
- Medium movement speed

Effective sebagai infantry utama.

---

## Spearman

Role:

Defensive infantry.

Characteristics:

- Medium HP
- Lower damage
- Higher defensive capability
- Longer melee range

Bagus untuk mempertahankan posisi.

---

## Axeman

Role:

Heavy melee damage.

Characteristics:

- High damage
- Medium HP
- Slow attack speed
- Lower defense

Bagus untuk menghancurkan infantry yang sudah engaged.

---

## Archer

Role:

Ranged support.

Characteristics:

- Low HP
- Low armor
- Long attack range
- Ranged damage

Archer harus menjaga jarak dari melee infantry.

---

## General

Role:

Army leader.

General bukan hanya unit dengan damage tinggi.

General memiliki:

- Command radius
- Morale bonus
- Small combat bonus

Contoh:

Units dalam radius General mendapatkan:

- +10 Morale
- +5% Damage

Jika General mati, seluruh army mendapatkan morale penalty.

---

# 5. Unit Stats

Setiap unit minimal memiliki:

- HP
- Damage
- Armor
- Attack Range
- Attack Speed
- Move Speed
- Morale
- Team
- Unit Type
- Current State
- Current Target

Example:

```gdscript
max_hp
current_hp

damage
armor

attack_range
attack_cooldown

move_speed

morale

unit_type
team
```

---

# 6. Combat System

Combat menggunakan sistem sederhana.

Basic damage calculation:

```text
Damage Received = Attacker Damage - Defender Armor
```

Minimum damage tetap harus ada agar attack tidak menghasilkan 0 damage.

Contoh:

```text
Minimum Damage = 1
```

Unit otomatis menyerang enemy terdekat jika:

- Enemy berada dalam attack range
- Unit tidak memiliki command yang melarang attack
- Unit tidak sedang routing

---

# 7. Unit Counter System

MVP dapat menggunakan modifier sederhana.

Contoh:

Swordsman:

```text
Strong vs Spearman
```

Spearman:

```text
Strong ketika defensive / holding position
```

Axeman:

```text
Strong vs Swordsman
```

Archer:

```text
Strong terhadap slow melee units
Weak ketika diserang melee
```

Modifier dapat menggunakan multiplier seperti:

```text
Normal Damage = 1.0x
Advantage = 1.25x
Strong Advantage = 1.5x
Disadvantage = 0.8x
```

---

# 8. Squad System

Unit tidak dikontrol satu per satu.

Beberapa soldiers membentuk satu squad.

Contoh:

```text
Swordsman Squad
10 Soldiers
```

Player memilih squad lalu memberikan command kepada seluruh squad.

Squad memiliki:

- Squad ID
- Unit Type
- List of Soldiers
- Formation
- Command
- Target
- Morale
- Average HP

Contoh:

```text
Squad A

Type:
Swordsman

Units:
10

Formation:
Line

Command:
Advance
```

---

# 9. Formation System

MVP memiliki empat formation.

## Line

```text
X X X X X X
```

Standard battle formation.

---

## Column

```text
X X
X X
X X
```

Lebih cocok untuk movement.

---

## Shield Wall

```text
X X X X X X
```

Memberikan defensive bonus.

Contoh:

```text
+15% Defense
-20% Movement Speed
```

---

## Wedge

```text
    X
   X X
  X X X
```

Lebih cocok untuk aggressive attack.

Contoh:

```text
+10% Damage
-10% Defense
```

Formation hanya menentukan posisi relatif soldiers dalam squad.

---

# 10. Command System

Player dapat memberikan beberapa command.

## Hold Position

Squad tetap berada di lokasi.

Unit hanya menyerang enemy yang masuk attack range.

---

## Advance

Squad bergerak menuju arah atau posisi target.

---

## Charge

Squad bergerak cepat menuju enemy target.

Possible bonus:

```text
Temporary Damage Bonus
```

---

## Defend

Squad fokus mempertahankan posisi.

Possible bonus:

```text
Defense Bonus
Reduced Movement
```

---

## Flank Left

Squad mencoba bergerak ke sisi kiri target.

---

## Flank Right

Squad mencoba bergerak ke sisi kanan target.

---

## Focus Target

Squad fokus menyerang target squad tertentu.

---

# 11. Unit State Machine

Setiap soldier menggunakan simple state machine.

Possible states:

```text
IDLE
MOVING
ATTACKING
CHASING
HOLDING
ROUTING
DEAD
```

Example:

```text
IDLE
↓
Enemy detected
↓
CHASING
↓
Enemy in range
↓
ATTACKING
↓
Enemy dead
↓
IDLE
```

Jika morale terlalu rendah:

```text
ANY STATE
↓
ROUTING
```

---

# 12. Morale System

Setiap squad memiliki morale dari:

```text
0–100
```

Example states:

```text
60–100 = Stable

30–59 = Shaken

1–29 = Routing

0 = Broken
```

Morale dapat turun ketika:

- Banyak soldiers mati
- General mati
- Squad diserang dari samping
- Squad diserang dari belakang
- Squad dikelilingi musuh
- Squad kalah jumlah

Morale dapat meningkat ketika:

- Dekat General
- Menang battle engagement
- Enemy squad mulai routing

Jika morale terlalu rendah, squad berhenti bertarung dan mencoba kabur dari battlefield.

---

# 13. Enemy AI

Enemy AI MVP tidak perlu kompleks.

AI hanya perlu:

1. Memilih squad player terdekat.
2. Bergerak menuju target.
3. Menyerang ketika masuk range.
4. Archer menjaga jarak.
5. General tetap berada dekat infantry.
6. Squad bereaksi terhadap routing.

Future AI dapat menggunakan tactical decision system.

---

# 14. Battlefield

MVP hanya memiliki satu battlefield.

Top-down 2D map.

Environment sederhana seperti:

- Grass
- Dirt
- Rocks
- Trees

Tidak perlu terrain effect untuk MVP.

Future version dapat menambahkan:

- High ground
- Forest
- River
- Mud
- Defensive terrain

---

# 15. Camera

Gunakan:

```text
Camera2D
```

Player dapat:

- Pan camera
- Zoom in
- Zoom out

Camera harus dapat melihat seluruh battlefield.

---

# 16. Player Controls

Mouse controls:

### Left Click

Select squad.

### Drag Selection

Optional setelah MVP.

### Right Click

Move squad atau memilih target.

### UI Buttons

Memberikan command:

```text
Hold
Advance
Charge
Defend
Flank Left
Flank Right
```

---

# 17. Battle UI

UI utama menampilkan:

### Selected Squad

```text
Swordsman

Units: 8 / 10

HP: 76%

Morale: 82

Formation: Line

Command: Hold
```

---

### Command Panel

Buttons:

```text
Hold

Advance

Charge

Defend

Flank Left

Flank Right
```

---

### Formation Panel

Buttons:

```text
Line

Column

Shield Wall

Wedge
```

---

### Battle Controls

```text
START BATTLE
```

Optional future:

```text
Pause
1x
2x
3x
```

---

# 18. Victory Conditions

Player menang jika:

```text
All enemy squads are dead
```

atau:

```text
All enemy squads are routing / broken
```

Player kalah dengan kondisi yang sama pada army sendiri.

---

# 19. Pixel Art Visual Style

Game menggunakan:

**Top-down 2D pixel art.**

Soldiers tidak perlu memiliki detail karakter kompleks.

Setiap unit cukup dibedakan melalui:

- Weapon
- Helmet
- Shield
- Clothes
- Small color indicator

Examples:

```text
Swordsman → Sword + Shield

Spearman → Long Spear

Axeman → Axe

Archer → Bow

General → Sword + Banner
```

Animation minimum:

```text
Idle

Walk

Attack

Death
```

Jika asset belum tersedia, gunakan temporary colored sprites atau simple placeholder pixel sprites.

Gameplay harus dapat berjalan tanpa final artwork.

---

# 20. Suggested Godot Scene Structure

```text
Battle.tscn

Battle
├── Battlefield
├── NavigationRegion2D
├── PlayerArmy
├── EnemyArmy
├── BattleManager
├── Camera2D
└── UI
```

---

## Unit Scene

```text
Unit.tscn

Unit
├── CharacterBody2D
├── Sprite2D
├── CollisionShape2D
├── NavigationAgent2D
└── HealthBar
```

---

## Squad Scene

```text
Squad.tscn

Squad
├── Units
├── FormationController
└── SquadController
```

---

# 21. Suggested Scripts

```text
battle_manager.gd

unit.gd

unit_stats.gd

unit_state_machine.gd

combat_system.gd

squad.gd

formation_manager.gd

command_manager.gd

morale_system.gd

enemy_ai.gd

general.gd

camera_controller.gd
```

---

# 22. Development Priority

## Phase 1 — Basic Battlefield

Create:

- Battlefield
- Camera movement
- Basic unit sprite
- Unit movement

Goal:

Units dapat bergerak di map.

---

## Phase 2 — Basic Combat

Create:

- HP
- Damage
- Attack range
- Target detection
- Death

Goal:

Dua soldiers dapat saling menyerang sampai salah satu mati.

---

## Phase 3 — Squad System

Create:

- Squad
- Squad selection
- Squad movement
- Multiple soldiers

Goal:

Player dapat mengontrol satu kelompok soldiers.

---

## Phase 4 — Formation System

Implement:

- Line
- Column
- Shield Wall
- Wedge

Goal:

Soldiers mempertahankan posisi relatif berdasarkan formation.

---

## Phase 5 — Commands

Implement:

- Hold
- Advance
- Charge
- Defend
- Focus Target

Flanking dapat dibuat setelah basic command stabil.

---

## Phase 6 — Army Battle

Create:

```text
Player Army

vs

Enemy Army
```

Enemy AI dapat bergerak dan menyerang player.

---

## Phase 7 — Morale

Implement:

- Morale loss
- General bonus
- Routing
- Broken squad

---

## Phase 8 — Polish

Add:

- Pixel-art sprites
- Attack animations
- Death animations
- Sound effects
- Battle UI
- Victory screen

---

# 23. Important Development Rules

Prioritize gameplay systems before graphics.

Do not build complex systems unless required for the current MVP.

Avoid:

- Campaign system
- Economy
- Diplomacy
- Multiplayer
- Procedural maps
- Equipment system
- Skill tree
- Complex character progression
- Base building
- Naval combat
- Siege system

until the core battle simulator is stable.

Architecture should remain modular so future unit types and battle mechanics can be added easily.

---

# 24. MVP Definition of Done

MVP dianggap selesai ketika:

1. Player dapat memilih squad.
2. Player dapat memindahkan squad.
3. Player dapat memilih formation.
4. Player dapat memberikan command.
5. Soldiers otomatis mencari dan menyerang musuh.
6. Archer dapat menyerang dari jarak jauh.
7. Unit dapat mati.
8. Squad memiliki morale.
9. Squad dapat routing.
10. General memberikan morale bonus.
11. Enemy AI dapat menyerang player.
12. Battle memiliki victory dan defeat condition.
13. Semua sistem berjalan pada satu battlefield dengan placeholder atau pixel-art sprites.

Final experience:

**A small-scale 2D pixel-art tactical battle simulator where players command squads, arrange formations, issue battlefield orders, and defeat an AI army through positioning, unit composition, combat, and morale management.**