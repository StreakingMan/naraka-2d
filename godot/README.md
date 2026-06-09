# Naraka 2D — Combat Demo (Godot 4)

Three-way克制 mechanic prototype: **普通攻击 / 蓄力攻击 / 振刀**.

- **Parry beats Charge** — well-timed parry catches the charge, attacker stunned
- **Normal beats Parry** — a normal swing breaks the parry stance, defender stunned
- **Charge beats Normal** — charge punishes an opponent caught mid-normal-swing, big damage + stun
- *Grazing rule*: Normal vs Charging stance → reduced damage, but the charge is NOT interrupted

Stick figures only, no art assets. Drawn entirely via `_draw()`.

## Running

1. Install [Godot 4.3+](https://godotengine.org/download) (use the standard/GDScript build, not the .NET one).
2. Open Godot → Import → pick `godot/project.godot` from this repo.
3. Press **F5** (or the play button) in the editor.

## Controls

| Key | Action |
|---|---|
| **A / D** (or ← / →) | Move left / right |
| **W** (or Space) | Jump |
| **S** (or ↓) | Crouch (hold) — lowers hurtbox |
| **Shift** | Roll dodge (i-frames during active window) — direction = facing, or hold opposite for back-roll |
| **J** (tap or hold) | Attack — **tap** = normal swing (cycles through 3 visual variants), **hold ~24f** = Tier 1 charge, **hold ~48f** = Tier 2 (heavy) charge. Held past max = auto-fires Tier 2. |
| **K / L** | Parry (16-frame active window — generous, designed to be reactable) |
| **TAB** | Toggle AI mode (Dummy / Trainer) |
| **F1** | Toggle hitbox / hurtbox debug overlay |
| **R** | Reset positions and HP |

## What's new in this iteration

- **Attack inertia preserved** — attacking while moving slides forward instead of stopping cold
- **Charge tiers** — Tier 1 = quicker / lower damage, Tier 2 = heavy / breaks parry hard
- **Crouch + Jump** — gravity reintroduced; crouch lowers hurtbox; jumping enables air-control + dive attacks
- **Roll dodge with i-frames** — `Shift` triggers a brief invulnerable roll. F1 debug overlay shows `iFRAMES` flag.

## How to test the triangle

1. Press **TAB** to put the opponent into **Trainer** mode — it cycles through Normal → Charge → Parry on a predictable 3-second loop.
2. Press **F1** to see hitboxes (red), hurtboxes (green), and parry windows (cyan).
3. Counter each of the trainer's attacks:
   - When trainer charges → press **J** during the charge windup → `CHARGE_INTERRUPTED`
   - When trainer attacks normally → press **L** just before contact → `PARRY_SUCCESS`
   - When trainer parries → hold **K** to charge, release into the parry window → `PARRY_BROKEN`

The outcome label appears briefly above each fighter on every resolve.

## Architecture (where to edit what)

| Want to tune… | Edit |
|---|---|
| Frame data (startup/active/recovery/damage) | `data/*.tres` |
| Stick figure poses | `scripts/pose_library.gd` |
| The triangle truth table | `scripts/combat_resolver.gd` |
| AI behavior | `scripts/ai_controller.gd` |
| Input mappings | `project.godot` `[input]` section |

See `CLAUDE.md` for Godot 4 syntax rules and AI-iteration conventions.
