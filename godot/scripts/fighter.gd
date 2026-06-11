class_name Fighter
extends CharacterBody2D

enum State {
	IDLE,
	WALK,
	CROUCH,
	JUMP,
	ROLL,
	ATTACK_NORMAL,
	CHARGING_UP,
	ATTACK_CHARGE_T1,
	ATTACK_CHARGE,
	PARRY,
	HIT,
	PARRIED,
}

const MAX_HP := 100
const WALK_SPEED := 140.0
const AIR_CONTROL_SPEED := 110.0
const JUMP_VELOCITY := -340.0
const GRAVITY := 1400.0
const MAX_FALL_SPEED := 700.0
const ROLL_SPEED := 340.0
const ATTACK_INERTIA_DECAY := 0.90
const CHARGE_INERTIA_DECAY := 0.85
const PARRY_INERTIA_DECAY := 0.85
const CROUCH_INERTIA_DECAY := 0.78
const ROLL_INERTIA_DECAY := 0.94
const PHYSICS_DT := 1.0 / 60.0

const HURTBOX_STAND_SIZE := Vector2(28, 50)
const HURTBOX_STAND_OFFSET := Vector2(0, -16)
const HURTBOX_CROUCH_SIZE := Vector2(28, 28)
const HURTBOX_CROUCH_OFFSET := Vector2(0, -7)

@export var is_player: bool = true
@export var fighter_name: String = "Fighter"
@export var body_tint: Color = Color(0.92, 0.92, 0.96)

# Optional sprite override. If set, _draw uses PoseLibrary.draw_sprite_pose
# instead of the stick-figure poses — state is expressed via tint/lean/squish.
var sprite_texture: Texture2D = null

# Optional rigged body parts. If set (takes priority over sprite_texture), _draw
# uses PoseLibrary.draw_rigged_pose — each limb is a textured sprite driven by
# the same joint positions the stick figure uses.
var body_sprites: BodySprites = null

@export var attack_normal_data: AttackFrameData
@export var attack_charge_t1_data: AttackFrameData
@export var attack_charge_data: AttackFrameData
@export var parry_data: AttackFrameData
@export var roll_data: AttackFrameData
@export var hit_normal_reaction: ReactionFrameData
@export var hit_charge_reaction: ReactionFrameData
@export var hit_parried_reaction: ReactionFrameData

var state: int = State.IDLE
var state_frame: int = 0
var facing: int = 1
var hp: int = MAX_HP
var hitstop_frames: int = 0
var flash_frames: int = 0
var flash_color: Color = Color(0, 0, 0, 0)
var did_hit_this_attack: bool = false
var charge_frames: int = 0
var charge_tier: int = 0
var attack_variant: int = 0   # cycles 0..2 to give normal attack visual variety
var last_outcome: int = -1
var last_outcome_frames: int = 0

var controller: RefCounted = null
var opponent: Node = null
var _ground_y: float = 0.0

var _hurtbox: Area2D
var _hitbox: Area2D
var _hurtbox_shape: CollisionShape2D
var _hitbox_shape: CollisionShape2D
var _intent: Dictionary = {}
var _buffered_intent: Dictionary = {}

func _ready() -> void:
	_build_hitboxes()
	hp = MAX_HP
	add_to_group(&"fighter")

func _build_hitboxes() -> void:
	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 1 << (0 if is_player else 1)
	_hurtbox.collision_mask = 1 << (3 if is_player else 2)
	_hurtbox.monitoring = true
	_hurtbox.monitorable = true
	_hurtbox_shape = CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = HURTBOX_STAND_SIZE
	_hurtbox_shape.shape = hurt_rect
	_hurtbox_shape.position = HURTBOX_STAND_OFFSET
	_hurtbox.add_child(_hurtbox_shape)
	add_child(_hurtbox)
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	_hitbox = Area2D.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = 1 << (2 if is_player else 3)
	_hitbox.collision_mask = 0
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox_shape = CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(10, 10)
	_hitbox_shape.shape = hit_rect
	_hitbox_shape.position = Vector2.ZERO
	_hitbox.add_child(_hitbox_shape)
	add_child(_hitbox)

func _physics_process(_delta: float) -> void:
	var raw_intent: Dictionary = controller.tick(self) if controller else {}
	_merge_intent_buffer(raw_intent)

	if last_outcome_frames > 0:
		last_outcome_frames -= 1

	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	_intent = _buffered_intent
	_buffered_intent = {}

	_update_facing()
	_resolve_state()
	_update_hitbox_from_frame_data()
	_update_hurtbox_state()
	_apply_motion()

	state_frame += 1
	if flash_frames > 0:
		flash_frames -= 1
		if flash_frames == 0:
			flash_color = Color(0, 0, 0, 0)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var flash: Color = flash_color if flash_frames > 0 else Color(0, 0, 0, 0)
	if body_sprites != null and body_sprites.is_complete():
		PoseLibrary.draw_rigged_pose(
			self,
			body_sprites,
			state,
			state_frame,
			facing,
			_current_charge_pct(),
			flash,
			attack_variant,
		)
	elif sprite_texture != null:
		PoseLibrary.draw_sprite_pose(
			self,
			sprite_texture,
			state,
			state_frame,
			facing,
			_current_charge_pct(),
			flash,
		)
	else:
		PoseLibrary.draw_pose(
			self,
			state,
			state_frame,
			facing,
			_current_charge_pct(),
			flash,
			attack_variant,
		)
	if last_outcome_frames > 0 and last_outcome >= 0:
		var label := CombatResolver.outcome_name(last_outcome)
		var font := ThemeDB.fallback_font
		var is_big := (
			last_outcome == CombatResolver.Outcome.PARRY_SUCCESS
			or last_outcome == CombatResolver.Outcome.PARRY_BROKEN
			or last_outcome == CombatResolver.Outcome.CHARGE_PUNISHES_NORMAL
		)
		var size: int = 24 if is_big else 12
		var color: Color = Color(1, 1, 0.6, 0.95)
		if last_outcome == CombatResolver.Outcome.PARRY_SUCCESS:
			color = Color(0.5, 1, 1, 1)              # cyan — parry caught the charge
		elif last_outcome == CombatResolver.Outcome.PARRY_BROKEN:
			color = Color(1, 0.5, 0.3, 1)            # orange — parry user got stunned
		elif last_outcome == CombatResolver.Outcome.CHARGE_PUNISHES_NORMAL:
			color = Color(1, 0.3, 0.3, 1)            # red — caught mid-swing
		elif last_outcome == CombatResolver.Outcome.NORMAL_GRAZES_CHARGE:
			color = Color(1, 0.85, 0.4, 0.9)         # amber — grazed
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
		var y_offset := -80 if is_big else -64
		draw_string(font, Vector2(-width * 0.5, y_offset), label, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)

func _merge_intent_buffer(raw: Dictionary) -> void:
	if raw.is_empty():
		return
	_buffered_intent["move"] = raw.get("move", 0)
	_buffered_intent["charge_hold"] = raw.get("charge_hold", false)
	_buffered_intent["crouch_hold"] = raw.get("crouch_hold", false)
	for k in [&"normal", &"charge_release", &"parry", &"jump", &"dodge"]:
		var ks := String(k)
		if raw.get(ks, false):
			_buffered_intent[ks] = true

func _update_facing() -> void:
	# Facing only updates when free (IDLE / WALK). Locked during attacks, jump, roll, crouch, stun.
	if not (state == State.IDLE or state == State.WALK):
		return
	if opponent == null:
		return
	var dx: float = opponent.global_position.x - global_position.x
	if abs(dx) > 4.0:
		facing = 1 if dx > 0 else -1

func _resolve_state() -> void:
	var move := int(_intent.get("move", 0))
	var pressed_normal := bool(_intent.get("normal", false))
	var holding_charge := bool(_intent.get("charge_hold", false))
	var released_charge := bool(_intent.get("charge_release", false))
	var pressed_parry := bool(_intent.get("parry", false))
	var pressed_jump := bool(_intent.get("jump", false))
	var holding_crouch := bool(_intent.get("crouch_hold", false))
	var pressed_dodge := bool(_intent.get("dodge", false))

	match state:
		State.IDLE, State.WALK:
			# Action priority: dodge > jump > parry > charge > crouch > normal > move
			if pressed_dodge:
				_start_roll(move)
				return
			if pressed_jump and is_on_ground():
				velocity.y = JUMP_VELOCITY
				_enter(State.JUMP)
				return
			if pressed_parry:
				_enter(State.PARRY)
				return
			if holding_charge:
				_enter(State.CHARGING_UP)
				return
			if holding_crouch:
				_enter(State.CROUCH)
				return
			if pressed_normal:
				_enter(State.ATTACK_NORMAL)
				# Carry slight forward momentum into the swing
				if move != 0:
					velocity.x = move * WALK_SPEED * 0.6
				return
			if move != 0:
				if state != State.WALK:
					_enter(State.WALK)
				velocity.x = move * WALK_SPEED
			else:
				if state != State.IDLE:
					_enter(State.IDLE)
				velocity.x = 0

		State.CROUCH:
			velocity.x *= CROUCH_INERTIA_DECAY
			# Allow direct cancel into roll / attack
			if pressed_dodge:
				_start_roll(move)
				return
			if pressed_normal:
				_enter(State.ATTACK_NORMAL)
				return
			if pressed_parry:
				_enter(State.PARRY)
				return
			if not holding_crouch:
				_enter(State.IDLE)

		State.JUMP:
			# Gravity is applied uniformly in _apply_motion for any airborne state — see there.
			if move != 0:
				velocity.x = move * AIR_CONTROL_SPEED
			if pressed_normal:
				_enter(State.ATTACK_NORMAL)
				return
			if is_on_ground() and velocity.y >= 0:
				_enter(State.IDLE)

		State.ROLL:
			# Iframes during active window (see _update_hurtbox_state).
			velocity.x *= ROLL_INERTIA_DECAY
			if state_frame >= roll_data.total_frames():
				_enter(State.IDLE)

		State.ATTACK_NORMAL:
			velocity.x *= ATTACK_INERTIA_DECAY
			if state_frame >= attack_normal_data.total_frames():
				_enter(State.IDLE)

		State.CHARGING_UP:
			velocity.x *= CHARGE_INERTIA_DECAY
			charge_frames += 1
			# Auto-fire tier 2 when held past max
			if charge_frames >= attack_charge_data.max_charge_frames:
				charge_tier = 2
				_enter(State.ATTACK_CHARGE)
				return
			# Releasing K resolves into one of three things based on hold duration
			if released_charge or not holding_charge:
				_resolve_charge_release()

		State.ATTACK_CHARGE_T1:
			velocity.x *= ATTACK_INERTIA_DECAY
			if state_frame >= attack_charge_t1_data.total_frames():
				_enter(State.IDLE)

		State.ATTACK_CHARGE:
			velocity.x *= ATTACK_INERTIA_DECAY
			if state_frame >= attack_charge_data.total_frames():
				_enter(State.IDLE)

		State.PARRY:
			velocity.x *= PARRY_INERTIA_DECAY
			if state_frame >= parry_data.total_frames():
				_enter(State.IDLE)

		State.HIT:
			var decay: float = hit_normal_reaction.knockback_decay
			velocity.x *= decay
			if state_frame >= hit_normal_reaction.stun_frames:
				_enter(State.IDLE)

		State.PARRIED:
			velocity.x *= hit_parried_reaction.knockback_decay
			if state_frame >= hit_parried_reaction.stun_frames:
				_enter(State.IDLE)

func _resolve_charge_release() -> void:
	# Three release tiers:
	#   too early   → cancel into ATTACK_NORMAL (no whiff penalty anymore)
	#   short hold  → ATTACK_CHARGE_T1 (light unblockable)
	#   long hold   → ATTACK_CHARGE (heavy unblockable)
	if charge_frames < attack_charge_t1_data.min_charge_frames:
		_enter(State.ATTACK_NORMAL)
	elif charge_frames < attack_charge_data.min_charge_frames:
		charge_tier = 1
		_enter(State.ATTACK_CHARGE_T1)
	else:
		charge_tier = 2
		_enter(State.ATTACK_CHARGE)

func _start_roll(move: int) -> void:
	# Default: forward roll. Press opposite direction: back-roll.
	var roll_dir: int = facing
	if move != 0 and sign(move) != facing:
		roll_dir = -facing
	velocity.x = roll_dir * ROLL_SPEED
	_enter(State.ROLL)

func is_on_ground() -> bool:
	return position.y >= _ground_y - 0.5

func _enter(new_state: int) -> void:
	# Cycle the normal-attack visual variant on each fresh entry so consecutive J presses
	# don't look identical. Hitbox/timing is unchanged across variants (visual only).
	if new_state == State.ATTACK_NORMAL and state != State.ATTACK_NORMAL:
		attack_variant = (attack_variant + 1) % 3
	if state != new_state:
		print("[STATE] %s: %s → %s (was @ frame %d)" % [fighter_name, _state_name_for_log(state), _state_name_for_log(new_state), state_frame])
	state = new_state
	state_frame = 0
	did_hit_this_attack = false
	# Use set_deferred — _enter is reachable from inside an Area2D signal callback
	# (via _apply_outcome → _take_hit → _enter), where direct property writes are blocked.
	_hitbox.set_deferred("monitorable", false)
	_hitbox.set_deferred("monitoring", false)
	# Preserve charge_frames only during CHARGING_UP → ATTACK_CHARGE_T1/T2 (for visual pct)
	if new_state != State.ATTACK_CHARGE and new_state != State.ATTACK_CHARGE_T1:
		charge_frames = 0
	if new_state != State.ATTACK_CHARGE and new_state != State.ATTACK_CHARGE_T1 and new_state != State.CHARGING_UP:
		charge_tier = 0

func _update_hitbox_from_frame_data() -> void:
	# States with no offensive hitbox: PARRY (defensive), CROUCH/JUMP/IDLE/WALK/ROLL (no swing), HIT/PARRIED.
	if state == State.PARRY or state == State.ROLL:
		_hitbox.monitorable = false
		_hitbox.monitoring = false
		return
	var fd: AttackFrameData = _current_attack_data()
	var active := false
	if fd != null and not did_hit_this_attack:
		active = state_frame >= fd.startup and state_frame < fd.startup + fd.active
		if active:
			_hitbox_shape.position = Vector2(fd.hitbox_offset.x * facing, fd.hitbox_offset.y)
			(_hitbox_shape.shape as RectangleShape2D).size = fd.hitbox_size
	_hitbox.monitorable = active
	_hitbox.monitoring = active

func _update_hurtbox_state() -> void:
	# Crouch lowers the hurtbox to dodge high attacks.
	var rect := _hurtbox_shape.shape as RectangleShape2D
	if state == State.CROUCH:
		rect.size = HURTBOX_CROUCH_SIZE
		_hurtbox_shape.position = HURTBOX_CROUCH_OFFSET
	else:
		rect.size = HURTBOX_STAND_SIZE
		_hurtbox_shape.position = HURTBOX_STAND_OFFSET
	# Roll iframes — disable monitoring during active window
	if state == State.ROLL and roll_data.is_active_at(state_frame):
		_hurtbox.monitoring = false
	else:
		_hurtbox.monitoring = true

func _apply_motion() -> void:
	# Universal gravity: any time we're above ground (or actively jumping), pull down.
	# This is more robust than only adding gravity inside the JUMP state branch — it
	# guarantees airborne fighters always settle, even on edge transitions (mid-attack,
	# mid-roll, etc.) that don't have their own gravity code.
	var airborne := not is_on_ground() or state == State.JUMP
	if airborne:
		velocity.y += GRAVITY * PHYSICS_DT
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED
	else:
		velocity.y = 0
	move_and_slide()
	# Ground clamp — stop falling through the floor.
	if position.y > _ground_y:
		position.y = _ground_y
		if velocity.y > 0:
			velocity.y = 0

func _current_attack_data() -> AttackFrameData:
	return attack_data_for_state(state)

func attack_data_for_state(s: int) -> AttackFrameData:
	match s:
		State.ATTACK_NORMAL: return attack_normal_data
		State.ATTACK_CHARGE_T1: return attack_charge_t1_data
		State.ATTACK_CHARGE: return attack_charge_data
		State.PARRY: return parry_data
		State.ROLL: return roll_data
	return null

func _current_charge_pct() -> float:
	if state == State.CHARGING_UP:
		var min_t1: float = float(attack_charge_t1_data.min_charge_frames)
		var max_t2: float = float(attack_charge_data.max_charge_frames)
		var span: float = max(1.0, max_t2 - min_t1)
		return clamp((float(charge_frames) - min_t1) / span, 0.0, 1.0)
	if state == State.ATTACK_CHARGE_T1:
		return 0.5
	if state == State.ATTACK_CHARGE:
		return 1.0
	return 0.0

func is_parry_active() -> bool:
	return state == State.PARRY and parry_data.is_active_at(state_frame)

func is_in_charge_stance() -> bool:
	# True for the whole charge sequence (windup + swing). Normal attacks landing on a
	# fighter in this state graze them — apply reduced damage but do NOT interrupt the charge.
	return (
		state == State.CHARGING_UP
		or state == State.ATTACK_CHARGE_T1
		or state == State.ATTACK_CHARGE
	)

func _on_hurtbox_area_entered(other: Area2D) -> void:
	if other.name != "Hitbox":
		return
	var attacker := other.get_parent() as Fighter
	if attacker == null or attacker == self:
		return
	if attacker.did_hit_this_attack:
		return

	# Normalize T1 charge to charge for resolver — both break parry, both can be interrupted same way.
	var attacker_action: int = attacker.state
	if attacker_action == State.ATTACK_CHARGE_T1:
		attacker_action = State.ATTACK_CHARGE

	var parry_active := is_parry_active()
	var in_charge := is_in_charge_stance()
	var outcome: int = CombatResolver.resolve(
		attacker_action,
		state,
		parry_active,
		in_charge,
	)
	var dist_x: float = abs(attacker.global_position.x - global_position.x)
	print("[HIT] dist=%.0f  attacker=%s(%s f=%d)  defender=%s(%s f=%d parry_active=%s in_charge=%s)  ⇒  %s" % [
		dist_x,
		attacker.fighter_name, attacker._state_name_for_log(attacker.state), attacker.state_frame,
		fighter_name, _state_name_for_log(state), state_frame, str(parry_active), str(in_charge),
		CombatResolver.outcome_name(outcome),
	])
	attacker.did_hit_this_attack = true
	# Defer — we're inside an Area2D signal callback.
	attacker._hitbox.set_deferred("monitorable", false)
	attacker._hitbox.set_deferred("monitoring", false)

	_apply_outcome(outcome, attacker)

func _apply_outcome(outcome: int, attacker: Fighter) -> void:
	last_outcome = outcome
	last_outcome_frames = 30
	attacker.last_outcome = outcome
	attacker.last_outcome_frames = 30

	match outcome:
		CombatResolver.Outcome.NORMAL_HIT:
			_take_hit(attacker, attacker.attack_normal_data, hit_normal_reaction)
		CombatResolver.Outcome.CHARGE_HIT:
			_take_hit(attacker, attacker.attack_data_for_state(attacker.state), hit_charge_reaction)
		CombatResolver.Outcome.CHARGE_PUNISHES_NORMAL:
			# Charge interrupts the defender's normal swing — heavy damage + extended stun
			_take_hit(attacker, attacker.attack_data_for_state(attacker.state), hit_charge_reaction)
		CombatResolver.Outcome.NORMAL_GRAZES_CHARGE:
			# Normal pokes a charging foe: small damage, brief flash, NO state change.
			# The defender continues to charge. The attacker's normal swing also continues.
			var raw_damage := attacker.attack_normal_data.damage
			hp = max(0, hp - int(raw_damage * 0.4))
			flash_color = Color(1.0, 0.7, 0.3, 0.7)
			flash_frames = 6
			hitstop_frames = 4
			attacker.hitstop_frames = 4
		CombatResolver.Outcome.PARRY_SUCCESS:
			# Parry catches incoming charge — attacker is stunned, defender unharmed.
			attacker._become_parried(self, hit_parried_reaction)
			hitstop_frames = parry_data.hitstop_frames
			flash_color = PoseLibrary.PARRY_COLOR
			flash_frames = 8
		CombatResolver.Outcome.PARRY_BROKEN:
			# Normal breaks the defender's parry stance — defender stunned.
			_become_parried(attacker, hit_parried_reaction)
			attacker.hitstop_frames = parry_data.hitstop_frames
			attacker.flash_color = Color(1, 0.5, 0.3, 0.8)
			attacker.flash_frames = 6
		_:
			pass

func _take_hit(attacker: Fighter, atk: AttackFrameData, reaction: ReactionFrameData) -> void:
	hp = max(0, hp - atk.damage)
	velocity = Vector2(atk.knockback.x * attacker.facing, atk.knockback.y)
	hitstop_frames = atk.hitstop_frames
	attacker.hitstop_frames = atk.hitstop_frames
	flash_color = reaction.flash_color
	flash_frames = reaction.flash_frames
	_enter(State.HIT)

func _become_parried(by_defender: Fighter, reaction: ReactionFrameData) -> void:
	velocity = Vector2(-30.0 * by_defender.facing, 0)
	hitstop_frames = parry_data.hitstop_frames
	flash_color = reaction.flash_color
	flash_frames = reaction.flash_frames
	_enter(State.PARRIED)

func reset(pos: Vector2) -> void:
	global_position = pos
	_ground_y = pos.y
	velocity = Vector2.ZERO
	hp = MAX_HP
	state = State.IDLE
	state_frame = 0
	hitstop_frames = 0
	flash_frames = 0
	charge_frames = 0
	charge_tier = 0
	did_hit_this_attack = false
	last_outcome = -1
	last_outcome_frames = 0

func get_hitbox_rect() -> Rect2:
	var size: Vector2 = (_hitbox_shape.shape as RectangleShape2D).size
	return Rect2(_hitbox_shape.position - size * 0.5, size)

func get_hurtbox_rect() -> Rect2:
	var size: Vector2 = (_hurtbox_shape.shape as RectangleShape2D).size
	return Rect2(_hurtbox_shape.position - size * 0.5, size)

func is_hitbox_active() -> bool:
	return _hitbox.monitorable

func is_invulnerable() -> bool:
	return state == State.ROLL and roll_data.is_active_at(state_frame)

func _state_name_for_log(s: int) -> String:
	match s:
		State.IDLE: return "IDLE"
		State.WALK: return "WALK"
		State.CROUCH: return "CROUCH"
		State.JUMP: return "JUMP"
		State.ROLL: return "ROLL"
		State.ATTACK_NORMAL: return "ATK_N(v%d)" % attack_variant
		State.CHARGING_UP: return "CHARGING"
		State.ATTACK_CHARGE_T1: return "ATK_C1"
		State.ATTACK_CHARGE: return "ATK_C2"
		State.PARRY: return "PARRY"
		State.HIT: return "HIT"
		State.PARRIED: return "PARRIED"
	return str(s)
