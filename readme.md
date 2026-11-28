# Beef Bruiser

A top-down 2D action prototype built in **Godot with GDScript**. Fight pursuing enemies in a starting arena, survive until its door opens, then navigate a randomized maze and use a color clue to choose the correct exit.

This README describes the source currently in this repository. Some features, including chest rewards, are not implemented yet.

## Contents

- [Quick start](#quick-start)
- [How to play](#how-to-play)
- [Controls](#controls)
- [Combat and weapons](#combat-and-weapons)
- [Enemies](#enemies)
- [Arena and maze](#arena-and-maze)
- [Repository layout](#repository-layout)
- [Code architecture](#code-architecture)
- [Configuration and tuning](#configuration-and-tuning)
- [Development workflow](#development-workflow)
- [Manual verification](#manual-verification)
- [Troubleshooting](#troubleshooting)
- [Current limitations](#current-limitations)
- [Credits and licensing](#credits-and-licensing)

## Quick start

### Requirements

- A Godot editor compatible with this project. `project.godot` declares **Godot 4.7** and the **Forward Plus** renderer; use the matching version when available. Compatibility with earlier Godot versions has not been established.
- A desktop keyboard and mouse.
- Graphics support appropriate for the selected renderer. The project specifies `d3d12` as its Windows rendering-device driver.

The project uses ordinary GDScript, so the .NET editor is not required. There are no package-manager installation steps or third-party Godot add-ons in the inspected source.

### Open and run in the editor

1. Obtain a complete copy of this repository, including `art/` and `weapons/`.
2. Open Godot's Project Manager and choose **Import**.
3. Select the repository's `project.godot` file.
4. Open the project and allow Godot to finish importing its assets.
5. Press **F6** with `test_map.tscn` open to run that scene, or **F5** to run the configured main scene.

The configured main-scene UID resolves to **`test_map.tscn`**. `Map.tscn` is the reusable map scene and does not itself contain the playable scene's player and spawner.

### Run from a terminal

If the Godot executable is on your `PATH` as `godot`:

```sh
cd /path/to/Beef-Bruiser
godot --editor --path .
```

To launch the game directly after importing the project:

```sh
godot --path .
```

Replace `godot` with your actual executable name or absolute executable path if needed. No exported executable or export preset is included in the inspected repository.

## How to play

1. **Survive the arena.** You begin with five health points, a sword, a shotgun, a flail ability, and dash enabled.
2. **Fight or evade enemies.** The main scene spawns an enemy every two seconds at one of three arena grid locations.
3. **Wait for the door.** After 20 seconds, the arena's right-hand door opens automatically. Enemy spawning stops; enemies already present remain.
4. **Read the clue.** A colored banner appears beside the opened arena door. Remember its color.
5. **Explore the maze.** Navigate rooms and connecting passages while avoiding traps.
6. **Choose the matching exit.** Of three marked exits, the one whose banner matches the arena clue is the real exit.

Entering the real exit displays **“Congratulations You Have Survived”**. A fake exit displays **“You have been Cowed!!”**. A trap displays **“You have stepped in cow min”**, preserving the current in-game text. Each of these outcomes pauses the scene.

Losing all health instead marks the player dead, stops player movement and weapon input, and turns the sprite sideways and gray. Player death currently has no dedicated result screen or automatic restart.

## Controls

| Input | Action | Notes |
| --- | --- | --- |
| **W / A / S / D** | Move | Diagonal input is normalized. |
| **Mouse** | Aim | Active weapons use mouse aiming by default. |
| **Hold left mouse button** | Attack | Repeats when the equipped weapon's cooldown allows. |
| **Space** | Dash | Uses the last movement direction; initially faces right. |
| **Q / E** | Previous / next active weapon | Cycles unlocked active weapons. |
| **1** | Equip sword | First active weapon in the player scene. |
| **2** | Equip shotgun | Second active weapon in the player scene. |
| **F** | Activate flail spin | Separate ability; does not require switching weapons. |
| **R** | Reload equipped weapon | Applies to the shotgun's ammo component. |
| **K** | Take one damage | Debug builds only; normal invulnerability checks apply. |
| **H** | Heal one health | Debug builds only; cannot revive a dead player. |
| **F2** | Reload current scene | Debug builds only, while input is still processing. |

Actions for weapon slots **3** and **4** exist in the Input Map, but there are only two active weapons in the current player scene. The flail is registered as a passive weapon and does not occupy an active slot.

After a trap or exit pauses the scene, stop and rerun it from the editor. The current pause flow does not provide an in-game restart menu, and the player's debug restart handler is not configured to process while paused.

## Combat and weapons

### Player movement and health

The player is a `CharacterBody2D` using floating motion, acceleration, friction, and `move_and_slide()`.

| Setting | Current value | Behavior |
| --- | --- | --- |
| Maximum health | 5 | Filled on scene startup. |
| Movement speed | 200 | World units per second. |
| Acceleration | 1,500 | Rate toward movement velocity. |
| Friction | 1,800 | Rate toward zero velocity. |
| Dash speed | 650 | World units per second. |
| Dash duration | 0.15 seconds | Locks velocity to the chosen dash direction. |
| Dash cooldown | 0.6 seconds | Starts when the dash begins. |
| Damage invulnerability | 1 second | Repeated contact damage is ignored during this period. |
| Damage knockback | 350 | Pushes away from the supplied damage source. |
| Hurt stun | 0.15 seconds | Temporarily prevents normal movement and active attacks. |

By default, dashing grants damage immunity and temporarily removes enemies from the player's collision mask. World-wall collisions remain enabled. Active mouse attacks are blocked during a dash; the flail has its own input condition and does not explicitly block dash activation.

Walking uses procedural sprite bobbing and tilt. Dashing stretches the sprite, and temporary damage invulnerability flashes it red with alternating opacity.

### Weapon settings

Values below include scene overrides, rather than only the defaults declared in scripts.

| Weapon | Damage | Cooldown | Behavior |
| --- | --- | --- | --- |
| Sword | 1 per target per swing | 0.35 seconds | 40-unit reach, 120-degree arc, 0.12-second swing. |
| Shotgun | 1 per pellet | 0.8 seconds | Five pellets across a 30-degree spread, with random angular jitter up to 4 degrees in either direction. |
| Flail | 3 per target per activation | 15 seconds | Two turns over 0.3 seconds, with a 55-unit orbit radius and a 6-unit ball radius. |

The sword begins equipped. Both active weapons and the flail begin unlocked. The flail's `passive` setting means it operates independently of the equipped weapon; activation still requires **F**.

The sword and flail record targets already hit during each attack to prevent repeated damage from the same swing or spin. Their visuals are drawn procedurally. Shotgun pellets also use procedural drawing.

### Shotgun ammunition and recoil

- The shotgun starts with **4 shells**, its full capacity.
- Each shot consumes one shell, regardless of the number of pellets spawned.
- Manual reload is enabled; automatic reload is disabled.
- Reloading restores **one shell every 0.4 seconds** until full. There is no separate finite reserve-ammunition pool.
- Firing interrupts reloading. Switching away also stops that weapon's reload.
- Killing an enemy with another weapon restores one shell to the shotgun, up to capacity. A shotgun kill does **not** refill its own ammo: the holder excludes the killing weapon from refill notifications.
- Each shot applies a recoil push of 250 opposite the aim direction, with a 0.08-second movement lock.

Pellets travel at 650 units per second with a nominal maximum range of 220 units. A `ShapeCast2D` sweeps their movement against world and enemy bodies, and pellets are removed on collision or after reaching their range. A ray check between the player's feet and the muzzle helps avoid spawning pellets through a wall.

## Enemies

All current variants inherit `enemy.tscn` and share contact-damage and health logic in `enemy.gd`. The shooter extends this script with ranged movement and attacks.

| Variant | Appearance | Speed | Hit points | Contact damage | Spawn probability |
| --- | --- | --- | --- | --- | --- |
| Normal cow | Default icon | 80 | 2 | 1 | 50% |
| Minotaur | Red tint | 120 | 2 | 2 | 20% |
| Mound cow | Green tint | 80 | 8 | 1 | 10% |
| Shooter cow | Blue tint | 80 | 1 | 1 | 20% |

The shooter cow approaches distant players, retreats within 100 units, and holds position at firing distance. With a clear line of sight and a target within 260 units, it fires a blue projectile every 1.8 seconds after an initial one-second delay. Shots deal one damage, travel at 180 units per second, and expire after 340 units. Walls block shots; enemy bodies do not. Player invulnerability and dash immunity apply. These settings are exported in `shooter_cow.gd`.

Enemies find the first node in the `player` group. Melee variants move directly toward it; shooters manage distance. Enemies stop movement and shooters stop firing when the player dies. They do not use navigation or pathfinding to route around maze walls. Contact damage is detected by overlapping the player's `player_hurtbox` area. Enemies are freed when their hit points reach zero.

## Arena and maze

### Generation and layout

`map.gd` builds the map at runtime:

- **Arena:** 67 columns by 55 rows, with an open interior and a five-cell-tall door on the right edge at rows 25–29.
- **Maze:** 217 columns by 55 rows, placed immediately to the arena's right.
- **Room arrangement:** Eight rooms across and six down. Each room's initial open interior is 26 columns by eight rows.
- **Passages:** Each room except the bottom-right opens a passage right or down, constrained at the outer edges.
- **Exits:** Two along the maze's right edge and one along the bottom edge. One is randomly selected as real.
- **Decorations and hazards:** Six chest placement attempts and 20 trap placement attempts, each occupying a six-by-two-cell region. Placements may overlap, so these are not guaranteed counts of distinct, nonoverlapping objects.

Exit labels 1, 2, and 3 are shuffled between exits. Their colors are **red**, **blue**, and **green**, respectively. The banner near the arena door uses the real exit's assigned color.

### Rendering and collisions

Each cell is based on a 9-by-26-unit grid with a default scale of 0.75, giving a rendered cell size of 6.75 by 19.5 units. The map is centered using the viewport dimensions during startup.

Map tiles are individual `Sprite2D` nodes under a runtime `MapLabel` holder. Walls are individual `StaticBody2D` nodes. Traps and exits receive per-cell `Area2D` triggers. When the door opens, the map removes and rebuilds its wall bodies and redraws its tile sprites.

The default logical viewport is **1920 × 1080**, with `canvas_items` stretching and `expand` aspect behavior. Texture filtering is set to nearest for sharp pixel art. The main scene enables Y sorting.

### Grid values

| Value | Meaning | Interaction |
| --- | --- | --- |
| `0` | Floor / open passage | Traversable. |
| `1` | Wall | Solid collision. |
| `2` | Arena door | Solid until the 20-second timer expires. |
| `3` | Real exit | Shows the victory message and pauses. |
| `4` | Fake exit | Shows the failure message and pauses. |
| `5` | Chest | Drawn, but no collection or reward behavior is implemented. |
| `6` | Trap | Shows the trap message and pauses immediately. |

## Repository layout

```text
Beef-Bruiser/
├── project.godot          # Engine settings, main scene, input actions, layers
├── test_map.tscn          # Playable main scene: map, player, enemy spawner
├── Map.tscn               # Reusable map root with map.gd attached
├── map.gd                 # Generation, rendering, walls, triggers, outcomes
├── player.tscn            # Player body, sprite, hurtbox, and weapon holder
├── player.gd              # Movement, dash, health, damage, animation, debug keys
├── enemy.tscn             # Shared enemy body and contact area
├── enemy.gd               # Pursuit, contact damage, hit points, death
├── enemy_spawner.gd       # Spawn timer, variant selection, spawn coordinates
├── minotaur.tscn          # Faster, higher-contact-damage enemy variant
├── mound_cow.tscn         # Higher-health enemy variant
├── shooter_cow.tscn       # Blue ranged enemy variant
├── shooter_cow.gd         # Distance management, line of sight, firing
├── cow_projectile.gd      # Enemy projectile sweep, wall collision, player damage
├── weapons/
│   ├── weapon.gd         # Shared weapon class and damage/kill hooks
│   ├── weapon_holder.gd  # Equipping, aiming, input, unlocks, kill refills
│   ├── ammo.gd           # Ammo capacity, shell reloads, refill signals
│   ├── sword.gd          # Melee arc, hit detection, drawing
│   ├── sword.tscn
│   ├── shotgun.gd        # Spread, pellet creation, muzzle check, recoil
│   ├── shotgun.tscn
│   ├── pellet.gd         # Projectile motion, shape casts, impact damage
│   ├── pellet.tscn
│   ├── flail.gd          # Spin input, radial sweep, procedural drawing
│   └── flail.tscn
├── art/
│   ├── Beef-Hero.png     # Player sprite
│   └── Map/              # Wall, floor, trap, chest, and colored banner PNGs
├── icon.svg              # Project icon and placeholder enemy texture
└── readme.md
```

Godot also uses `.gd.uid` sidecars and `.import` metadata. The `.godot/` directory is generated editor/import cache and is ignored by Git. The current `.gitignore` also excludes `/android/`.

## Code architecture

### Scene composition

```text
Map                         test_map.tscn, inherited from Map.tscn
├── Player                  player.tscn
│   ├── Sprite2D
│   ├── CollisionShape2D
│   ├── WeaponHolder
│   │   ├── Sword
│   │   ├── Shotgun
│   │   │   └── Ammo
│   │   └── Flail
│   └── Hurtbox
│       └── CollisionShape2D
└── EnemySpawner
    ├── Spawn1
    └── Spawn2
```

The map adds tile sprites, wall bodies, triggers, messages, and spawned enemies at runtime. Shotgun pellets are added to the current scene.

`Spawn1` and `Spawn2` are currently unused markers. The spawner selects from its `spawn_cells` array instead: `(30, 27)`, `(45, 15)`, and `(45, 40)`, measured in arena grid coordinates.

### Script responsibilities and interfaces

- **`Player`:** Owns movement and health state. Exposes `take_damage()`, `heal()`, `push()`, and `unlock_dash()`, plus `health_changed(current, maximum)` and `died` signals.
- **`Weapon`:** Base `Node2D` class for attack cooldowns, optional ammo, damage calls, and kill notifications. Exposes `attacked` and `killed(target)` signals and hooks for attack, per-frame weapon behavior, and equip transitions.
- **Weapon holder:** Discovers `Weapon` children, assigns their player reference, separates active weapons from passives, and connects kill signals. Emits `weapon_changed(weapon)` and supports `unlock_weapon(name, equip_now)`.
- **`Ammo`:** Tracks shell count and per-shell reload timing. Emits `ammo_changed(current, maximum)`, `reload_started`, and `reload_finished`.
- **Enemy:** Exposes `take_damage(amount)` and queues itself for deletion at zero hit points. The base weapon uses queued deletion to recognize kills.
- **Spawner:** Assumes its parent exposes `door_open`, `map_x`, `map_y`, `CELL_W`, `CELL_H`, and `tile_scale`. It stops its timer once the door opens or no player instance exists.
- **Map:** Owns arena/maze data and outcome triggers. Exit and trap callbacks currently identify the player by the exact node name `Player`.

### Collision layers and groups

| Item | Configuration / purpose |
| --- | --- |
| Physics layer 1 | Named `world`; also used by the player's body and hurtbox with their default layer settings. |
| Physics layer 2 | Named `enemies`; enemy bodies use this layer. |
| Mask `3` | Bitmask selecting both layers 1 and 2; used by player/enemy bodies, sword hitbox, and pellets. |
| `player` group | Used to locate the player; assigned in the scene and ensured by `Player._ready()`. |
| `player_hurtbox` group | Identifies the area that enemies use for contact damage. |

The player's hurtbox has monitoring disabled but remains detectable by the enemy contact area's monitoring. The flail's runtime area monitors enemy bodies only.

## Configuration and tuning

Prefer changing exported properties in the Godot Inspector. Remember that scene overrides take precedence over script defaults.

| Change | Location | Current configuration |
| --- | --- | --- |
| Window size and stretch | `project.godot` → Display | 1920 × 1080, canvas-items stretch, expanded aspect. |
| Keyboard/mouse bindings | Project Settings → Input Map | Actions listed in [Controls](#controls). |
| Player movement, health, dash | `player.gd` exports / Player Inspector | Defaults documented above. |
| Walk animation | Player instance in `test_map.tscn` | Bob speed 10 and tilt 2 degrees override script defaults. |
| Arena duration | `map.gd`, `door_timer()` | Hard-coded 20 seconds. |
| Map scale and player spawn | Map Inspector / `map.gd` | Scale 0.75; spawn cell `(10, 27)`. |
| Spawn rate | EnemySpawner in `test_map.tscn` | 2 seconds; overrides the script's 0.25-second default. |
| Enemy scale | `enemy_spawner.gd` export | 0.3 uniform scale. |
| Enemy spawn locations | `enemy_spawner.gd`, `spawn_cells` | Three arena cells, independent of marker positions. |
| Enemy probabilities | `enemy_spawner.gd`, `spawn_enemy()` | 10% mound, 20% minotaur, 20% shooter, 50% normal. |
| Enemy stats | Base and inherited enemy scenes | Variant values documented above. |
| Active weapon order | WeaponHolder children in `player.tscn` | Sword, then shotgun; passive flail excluded. |
| Aim behavior | WeaponHolder Inspector | Mouse by default; `FACING` mode uses movement facing. |
| Damage and cooldown | Individual weapon scenes | Scene values documented above. |
| Flail turns | Flail instance in `player.tscn` | Two turns override the script's one-turn default. |
| Ammo/reload behavior | Shotgun's Ammo child | Four shells; manual per-shell reload. |

**Scale caveat:** `tile_width` and `tile_height` are initialized from `tile_scale` as ordinary member variables, rather than recalculated in `_ready()`. If changing the exported scale produces mismatched visuals, triggers, walls, or spawn positions, review that initialization and recalculate both dimensions consistently. Changing map scale also does not automatically scale player movement or all combat dimensions.

## Development workflow

### Making changes

1. Open `test_map.tscn` as the primary playable integration scene.
2. Keep reusable player, enemy, and weapon behavior in their existing scenes and scripts.
3. Use the Inspector for tuning; check both reusable scenes and their inherited/instanced overrides.
4. Run the main scene and inspect Godot's Output and Debugger panels.
5. Review the Git diff before committing, including scene changes and generated metadata.

There is no automated test suite or CI configuration in the inspected repository.

### Adding a weapon

1. Create a script extending `Weapon` and a corresponding scene with a `Node2D` root.
2. Override `attack(aim)` and, if necessary, `_weapon_physics(delta)` and `_draw()`.
3. Set `weapon_name`, `damage`, `cooldown`, and any custom exported settings.
4. For ammunition, add a child named exactly `Ammo` with `ammo.gd` attached.
5. Instance the weapon under the player's `WeaponHolder` so the holder discovers it and assigns its player reference.
6. Set `passive = true` only for a separately operating ability. Implement its activation behavior in the weapon script, as the flail does.
7. Route damage through `deal_damage()` to preserve kill notifications and ammunition-refill behavior.
8. Verify slot order, equip transitions, cooldowns, and any new Input Map action.

The holder supports direct selection for up to four active weapons. Its cycling logic can traverse the full active-weapon list.

### Adding an enemy variant

1. Create an inherited scene from `enemy.tscn`.
2. Override speed, hit points, contact damage, or appearance as needed.
3. Implement a custom script if the variant needs behavior beyond direct pursuit.
4. Add a preload and selection branch to `enemy_spawner.gd` if it should appear during normal play.
5. Preserve the expected damage interface and contact-area structure, or update consumers consistently.

### Exporting a build

Configure a platform preset through Godot's **Project → Export** workflow and install matching export templates if needed. No `export_presets.cfg` is currently included, so there is no repository-defined platform preset or one-command release process.

Debug-only keys depend on `OS.is_debug_build()` and should not be assumed to exist in a release export.

## Manual verification

Use this checklist after changing gameplay. It describes checks to perform, not a claim that this revision has passed runtime testing.

- Start `test_map.tscn`; confirm the player appears inside the arena and the sword starts equipped.
- Move in all directions; verify acceleration, stopping, sprite facing, and wall collision.
- Dash while moving and while stationary; verify direction, cooldown, enemy pass-through, and damage immunity.
- Hold left click with the sword; confirm enemies take damage and are removed at zero hit points.
- Equip the shotgun, fire four shots, verify empty-fire behavior, then reload one shell at a time.
- Interrupt a reload by firing and by switching weapons.
- Kill with the sword or flail while shotgun ammo is missing; verify one-shell refill. Verify shotgun kills do not refill their own shells.
- Activate the flail with **F**; verify two turns and the 15-second cooldown.
- Verify shooters approach at long range, retreat at close range, and fire only with clear line of sight. Check that walls block projectiles, enemy bodies do not, and dashing or damage invulnerability prevents projectile damage. Confirm firing stops when the player dies.
- Observe enemy variants over multiple runs; check pursuit, contact damage, knockback, and invulnerability flashes.
- Survive for 20 seconds; verify the door opens, a clue banner appears, and new spawning stops.
- Confirm existing enemies remain after the door opens.
- Across separate runs, enter the matching exit, a mismatched exit, and a trap; verify their respective messages and paused state.
- Verify health reaching zero stops player control and changes the sprite without expecting an outcome menu.
- Restart repeatedly to check randomized passages, exit assignments, and decoration placement.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Project fails to import or parse | Confirm editor compatibility with the declared Godot 4.7 project format and inspect the first error in Godot's Debugger. |
| Main scene cannot be resolved | Allow asset import to finish, then open `test_map.tscn` directly and set it as the main scene if necessary. |
| Only the map appears | Run `test_map.tscn`; `Map.tscn` alone has no player or spawner instances. |
| Missing textures or resource errors | Confirm `art/Beef-Hero.png` and every referenced PNG under `art/Map/` are present with matching filename case. |
| Renderer fails on startup | Review the Forward Plus renderer and the Windows D3D12 driver setting against the local editor/hardware setup. A renderer change needs local verification. |
| Shotgun no longer fires | Equip it and press **R**; it may be empty. Automatic reload is disabled. |
| Flail does not appear in weapon cycling | It is intentionally configured as a passive ability; press **F**. |
| Enemy spawn rate seems different from the script | The main scene overrides `spawn_interval` to 2 seconds. |
| Moving spawn markers has no effect | Edit `spawn_cells`; the markers are not read by the current spawner. |
| Game stops after entering a trap or exit | This is the current outcome behavior: the scene tree is paused. Stop and rerun the scene. |
| Health or ammo is hard to track | There is no HUD yet. Inspect the Output panel, exported state, or connect the existing signals to UI. |
| Enemies get stuck against maze walls | Their AI pursues directly and has no pathfinding. |
| Chests do nothing | They currently provide visuals and grid markings only. |
| Terminal says `godot` is not found | Use the installed executable's absolute path or configure your shell's `PATH`. |

## Current limitations

- No title screen, pause menu, health/ammo HUD, score system, save system, or release restart flow is implemented in the inspected scenes.
- Player death is separate from the map's `game_over` flag and paused outcome flow. The map does not connect the player's `died` signal to an end screen.
- The spawner checks player instance validity, not `is_dead`, so player death alone does not stop spawning before the arena door opens.
- Chests do not grant items, healing, or weapon unlocks. Unlock APIs exist, but no pickup progression is connected to them.
- Random chest/trap placements may overlap; the latest placement changes the underlying grid while both drawing lists retain their entries. This can make displayed decorations differ from the final interaction cells.
- Exit/trap recognition depends on the player node being named `Player`.
- Map generation creates many individual sprite, physics-body, and trigger nodes. Large-map performance and the door-opening rebuild should be measured before expanding the map.
- The map is centered at startup; no resize-driven recentering or camera-follow system is implemented.
- No deterministic random-seed control is exposed for reproducing a particular maze.
- Automated tests, export presets, and CI are not provided.

These are observations about the current implementation, not promised future features.

## Credits and licensing

The repository contains a custom player image, map textures, and a Godot icon used as a placeholder enemy texture. The inspected files do not include an author/contributor list, asset-source credits, or a project license.

Add contributor names, original asset sources, attribution requirements, and the intended license before distributing the project. Do not assume that the absence of a license grants permission to reuse or redistribute its code or assets.
