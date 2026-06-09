class_name AttackFrameData
extends Resource

@export var startup: int = 6
@export var active: int = 3
@export var recovery: int = 10

@export var damage: int = 10
@export var hitstop_frames: int = 6
@export var knockback: Vector2 = Vector2(180, -30)

@export var hitbox_offset: Vector2 = Vector2(30, -10)
@export var hitbox_size: Vector2 = Vector2(40, 30)

@export var unblockable: bool = false
@export var breaks_parry: bool = false

@export var min_charge_frames: int = 0
@export var max_charge_frames: int = 0

func total_frames() -> int:
	return startup + active + recovery

func is_active_at(frame: int) -> bool:
	return frame >= startup and frame < startup + active
