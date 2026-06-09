# Claude conventions for `godot/`

## Engine version: Godot 4.3+

This is a **Godot 4** project. Never generate Godot 3 syntax.

| Wrong (Godot 3) | Right (Godot 4) |
|---|---|
| `KinematicBody2D` | `CharacterBody2D` |
| `export var foo` | `@export var foo` |
| `onready var node = $N` | `@onready var node: Node = $N` |
| `signal.connect("name", obj, "method")` | `signal.connect(callable)` |
| `move_and_slide(velocity)` | set `velocity` then call `move_and_slide()` |
| `Tween` as method | `Tween` is a Node, created with `create_tween()` |
| `yield(...)` | `await` |
| `func _ready() -> void` (still works but…) | Type hints encouraged on all signatures |

## Architectural rules (non-negotiable)

1. **Kinematic movement only.** Never introduce `RigidBody2D` or physics forces for characters. Direct velocity assignment, `move_and_slide()`, and scripted knockback decay.
2. **All combat logic in `_physics_process` (60 Hz fixed).** Visuals (poses, redraws, debug overlay) live in `_process`. Never write combat state from `_process`.
3. **Hitboxes / Hurtboxes are `Area2D`, overlap-detection only.** Never use them for physical collision. The `monitoring` / `monitorable` flags drive activation.
4. **Frame data lives in `.tres` Resource files**, never hardcoded. Editing `data/*.tres` is the primary tuning surface.
5. **State transitions go through `Fighter._enter(State)` — single chokepoint.** Resets `state_frame`, toggles flags, never modify `state` directly elsewhere.
6. **Hit-stop is a per-fighter integer counter**, not `Engine.time_scale` or `get_tree().paused`. Those freeze the debug overlay we want running during impact.

## Hot loops — where to edit for common changes

| Goal | File |
|---|---|
| Tune attack startup/active/recovery/damage | `data/attack_*.tres`, `data/hit_*.tres`, `data/parry.tres` |
| Change a stick figure pose | `scripts/pose_library.gd` |
| Change the三角克制 truth table | `scripts/combat_resolver.gd` |
| Add a new AI mode | `scripts/ai_controller.gd` |
| Rebind keys | `project.godot` `[input]` section |
| Change collision layers | `project.godot` `[layer_names]` + per-Area2D in scenes |

## Adding a new attack

1. Create `data/attack_<name>.tres` referencing the `AttackFrameData` script.
2. Add to `State` enum in `fighter.gd`.
3. Add a case in `Fighter._resolve_state()` for tick logic.
4. Add a pose generator in `pose_library.gd`.
5. Wire input → intent → enter in `input_controller.gd` (or `ai_controller.gd`).
6. If the attack has special克制 properties, add a branch in `combat_resolver.gd`.

## Determinism contract

- `_physics_process` runs at exactly 60 Hz. Use `state_frame: int` as the canonical time, never `delta`.
- Frame data uses integer frame counts (`startup: int`, not seconds).
- `_process` may read combat state for rendering but MUST NOT mutate it.
- Random calls in gameplay should use a seeded RNG (none yet — add when AI variability is needed).

## What NOT to add

- RigidBody2D for any gameplay-relevant entity
- AnimationPlayer / AnimationTree for combat logic (visuals only if we ever add it)
- Multiple scenes for fighters (one fighter scene is fine if needed, but currently fighters are spawned from `main.gd`)
- Real art assets (this is a stick-figure prototype until the triangle feel is locked in)
- Sound effects (deferred until polish phase)
- Network code

## Running / verifying

- Open in Godot editor → F5 to play
- Headless smoke (when Godot CLI is installed): `godot --headless --quit --path .` — should exit 0 with no parse errors
