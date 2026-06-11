class_name PoseLibrary
extends RefCounted

const BODY_COLOR := Color(0.92, 0.92, 0.96)
const WEAPON_COLOR := Color(0.75, 0.78, 0.92)
const CHARGE_COLOR := Color(1.0, 0.85, 0.25)
const CHARGE_FULL_COLOR := Color(1.0, 0.4, 0.1)
const PARRY_COLOR := Color(0.45, 0.95, 1.0)
const HIT_COLOR := Color(1.0, 0.3, 0.3)
const STUNNED_COLOR := Color(0.6, 0.6, 0.7)

const LIMB_WIDTH := 2.5
const WEAPON_WIDTH := 3.5

# Joint reference points (facing right by default; mirror X by facing for left).
const HEAD_POS := Vector2(0, -42)
const HEAD_RADIUS := 7.0
const NECK := Vector2(0, -32)
const HIP := Vector2(0, 8)

# Draws a stick figure for the given state at the given frame.
# canvas: the Fighter node (CanvasItem) we draw into
# state: Fighter.State enum value
# frame: state_frame
# facing: +1 (right) or -1 (left)
# charge_pct: 0.0–1.0 for CHARGING_UP / ATTACK_CHARGE visual buildup
# flash_color: optional overlay color (set alpha 0 to skip)
static func draw_pose(
	canvas: CanvasItem,
	state: int,
	frame: int,
	facing: int,
	charge_pct: float,
	flash_color: Color,
	attack_variant: int = 0,
) -> void:
	var body_color := BODY_COLOR
	var weapon_color := WEAPON_COLOR

	match state:
		Fighter.State.IDLE:
			_draw_idle(canvas, frame, facing, body_color, weapon_color)
		Fighter.State.WALK:
			_draw_walk(canvas, frame, facing, body_color, weapon_color)
		Fighter.State.CROUCH:
			_draw_crouch(canvas, frame, facing, body_color, weapon_color)
		Fighter.State.JUMP:
			_draw_jump(canvas, frame, facing, body_color, weapon_color)
		Fighter.State.ROLL:
			_draw_roll(canvas, frame, facing, body_color)
		Fighter.State.ATTACK_NORMAL:
			_draw_attack_normal(canvas, frame, facing, body_color, weapon_color, attack_variant)
		Fighter.State.CHARGING_UP:
			_draw_charging_up(canvas, frame, facing, charge_pct)
		Fighter.State.ATTACK_CHARGE_T1:
			_draw_attack_charge(canvas, frame, facing, 0.5)
		Fighter.State.ATTACK_CHARGE:
			_draw_attack_charge(canvas, frame, facing, charge_pct)
		Fighter.State.PARRY:
			_draw_parry(canvas, frame, facing)
		Fighter.State.HIT:
			_draw_hit(canvas, frame, facing)
		Fighter.State.PARRIED:
			_draw_parried(canvas, frame, facing)

	if flash_color.a > 0.0:
		canvas.draw_circle(HEAD_POS, 22.0, Color(flash_color.r, flash_color.g, flash_color.b, flash_color.a * 0.6))

static func _mirror_x(v: Vector2, facing: int) -> Vector2:
	return Vector2(v.x * facing, v.y)

static func _draw_torso(canvas: CanvasItem, body_color: Color) -> void:
	canvas.draw_circle(HEAD_POS, HEAD_RADIUS, body_color)
	canvas.draw_line(NECK, HIP, body_color, LIMB_WIDTH)

static func _draw_idle(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	_draw_torso(canvas, body_color)
	# Breath: tiny bob in head height
	var bob := sin(frame * 0.08) * 0.6
	canvas.draw_circle(HEAD_POS + Vector2(0, bob), HEAD_RADIUS, body_color)
	# Legs
	canvas.draw_line(HIP, _mirror_x(Vector2(-7, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(7, 32), facing), body_color, LIMB_WIDTH)
	# Off-hand arm
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-10, -8), facing), body_color, LIMB_WIDTH)
	# Weapon arm (in front)
	var hand := _mirror_x(Vector2(11, -6), facing)
	canvas.draw_line(Vector2(0, -25), hand, body_color, LIMB_WIDTH)
	# Sheathed weapon
	canvas.draw_line(hand, hand + _mirror_x(Vector2(18, 4), facing), weapon_color, WEAPON_WIDTH)

static func _draw_walk(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	_draw_torso(canvas, body_color)
	var phase := frame * 0.35
	var leg_swing := sin(phase) * 8.0
	canvas.draw_line(HIP, Vector2(-7 + leg_swing, 32), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, Vector2(7 - leg_swing, 32), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-10, -6 + leg_swing * 0.3), facing), body_color, LIMB_WIDTH)
	var hand := _mirror_x(Vector2(11, -6 - leg_swing * 0.3), facing)
	canvas.draw_line(Vector2(0, -25), hand, body_color, LIMB_WIDTH)
	canvas.draw_line(hand, hand + _mirror_x(Vector2(18, 4), facing), weapon_color, WEAPON_WIDTH)

# Normal attack: startup=5, active=3, recovery=12 (see attack_normal.tres)
# variant: 0 = thrust (straight stab), 1 = side slash (横扫), 2 = downward chop (下劈)
# All variants share frame data — only the weapon arc differs visually.
static func _draw_attack_normal(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color, variant: int) -> void:
	_draw_torso(canvas, body_color)
	# Legs braced
	canvas.draw_line(HIP, _mirror_x(Vector2(-10, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(8, 32), facing), body_color, LIMB_WIDTH)
	# Off-hand
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-8, -10), facing), body_color, LIMB_WIDTH)

	match variant:
		1: _draw_attack_normal_slash(canvas, frame, facing, body_color, weapon_color)
		2: _draw_attack_normal_chop(canvas, frame, facing, body_color, weapon_color)
		_: _draw_attack_normal_thrust(canvas, frame, facing, body_color, weapon_color)

# Variant 0: straight thrust (the original animation).
static func _draw_attack_normal_thrust(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	var hand_pos: Vector2
	var weapon_tip: Vector2
	if frame < 5:
		var t = float(frame) / 5.0
		hand_pos = _mirror_x(Vector2(lerpf(11.0, -8.0, t), lerpf(-6.0, -22.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(-10, -12), facing)
	elif frame < 8:
		hand_pos = _mirror_x(Vector2(18, -10), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(28, 4), facing)
	else:
		var t = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
		hand_pos = _mirror_x(Vector2(lerpf(18.0, 11.0, t), lerpf(-10.0, -6.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(lerpf(28.0, 18.0, t), 4), facing)
	canvas.draw_line(Vector2(0, -25), hand_pos, body_color, LIMB_WIDTH)
	canvas.draw_line(hand_pos, weapon_tip, weapon_color, WEAPON_WIDTH)

# Variant 1: horizontal slash (sweeps from low-back to high-front).
static func _draw_attack_normal_slash(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	var hand_pos: Vector2
	var weapon_tip: Vector2
	if frame < 5:
		# Startup: weapon swung down-and-back
		var t = float(frame) / 5.0
		var angle := lerpf(PI * 0.9, PI * 0.6, t)
		hand_pos = _mirror_x(Vector2(cos(angle) * 14.0, sin(angle) * 14.0 - 8.0), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(cos(angle - 0.4) * 24.0, sin(angle - 0.4) * 24.0), facing)
	elif frame < 8:
		# Active: arcing forward sweep
		var t = float(frame - 5) / 3.0
		var angle := lerpf(PI * 0.6, -PI * 0.1, t)
		hand_pos = _mirror_x(Vector2(cos(angle) * 16.0, sin(angle) * 12.0 - 10.0), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(cos(angle - 0.3) * 30.0, sin(angle - 0.3) * 18.0), facing)
		# Slash trail dots
		canvas.draw_circle(weapon_tip, 4.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.5))
	else:
		var t = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
		hand_pos = _mirror_x(Vector2(lerpf(20.0, 11.0, t), lerpf(-8.0, -6.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(lerpf(26.0, 18.0, t), 4), facing)
	canvas.draw_line(Vector2(0, -25), hand_pos, body_color, LIMB_WIDTH)
	canvas.draw_line(hand_pos, weapon_tip, weapon_color, WEAPON_WIDTH)

# Variant 2: downward chop (overhead → down-forward).
static func _draw_attack_normal_chop(canvas: CanvasItem, frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	var hand_pos: Vector2
	var weapon_tip: Vector2
	if frame < 5:
		# Startup: lift weapon overhead
		var t = float(frame) / 5.0
		hand_pos = _mirror_x(Vector2(lerpf(11.0, 2.0, t), lerpf(-6.0, -34.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(0, lerpf(-18.0, -26.0, t)), facing)
	elif frame < 8:
		# Active: chop down to forward-low
		var t = float(frame - 5) / 3.0
		var angle := lerpf(-PI * 0.5, PI * 0.15, t)
		hand_pos = _mirror_x(Vector2(cos(angle) * 14.0 + 4.0, sin(angle) * 16.0 - 10.0), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(cos(angle - 0.2) * 28.0, sin(angle - 0.2) * 22.0 + 2.0), facing)
		canvas.draw_circle(weapon_tip, 3.5, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.4))
	else:
		var t = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
		hand_pos = _mirror_x(Vector2(lerpf(20.0, 11.0, t), lerpf(8.0, -6.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(lerpf(28.0, 18.0, t), lerpf(14.0, 4.0, t)), facing)
	canvas.draw_line(Vector2(0, -25), hand_pos, body_color, LIMB_WIDTH)
	canvas.draw_line(hand_pos, weapon_tip, weapon_color, WEAPON_WIDTH)

static func _draw_charging_up(canvas: CanvasItem, frame: int, facing: int, charge_pct: float) -> void:
	# Because J now triggers charge AND a quick tap fires a normal attack,
	# we delay the visible "raised weapon" until frame 6 — short taps don't
	# flicker a windup pose before transitioning to ATTACK_NORMAL.
	var body_color := BODY_COLOR
	_draw_torso(canvas, body_color)
	canvas.draw_line(HIP, _mirror_x(Vector2(-9, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(9, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-10, -8), facing), body_color, LIMB_WIDTH)

	# Smoothly interpolate the weapon arm from idle stance to raised stance over frames 0..10.
	var t: float = clampf(float(frame) / 10.0, 0.0, 1.0)
	var hand_idle: Vector2 = _mirror_x(Vector2(11, -6), facing)
	var hand_raised: Vector2 = _mirror_x(Vector2(-4, -32), facing)
	var hand: Vector2 = hand_idle.lerp(hand_raised, t)
	canvas.draw_line(Vector2(0, -25), hand, body_color, LIMB_WIDTH)

	# Weapon line follows the same lerp. Glow only becomes visible once we're noticeably wound up.
	var tip_offset_idle: Vector2 = _mirror_x(Vector2(18, 4), facing)
	var tip_offset_raised: Vector2 = _mirror_x(Vector2(-4, -28), facing)
	var tip_offset: Vector2 = tip_offset_idle.lerp(tip_offset_raised, t)
	var weapon_tip: Vector2 = hand + tip_offset

	var glow_color: Color = WEAPON_COLOR.lerp(CHARGE_COLOR, t).lerp(CHARGE_FULL_COLOR, charge_pct * t)
	canvas.draw_line(hand, weapon_tip, glow_color, WEAPON_WIDTH + t)

	# Pulse halo only after t > 0.5 (i.e. ~5+ frames in) so tap presses don't show anything.
	if t > 0.5:
		var pulse: float = (sin(float(frame) * 0.5) * 0.5 + 0.5) * 0.5 + 0.5
		var glow_radius: float = (4.0 + charge_pct * 6.0 * pulse) * (t - 0.5) * 2.0
		canvas.draw_circle(weapon_tip, glow_radius, Color(glow_color.r, glow_color.g, glow_color.b, 0.5 * t))

# Charge attack: startup=10, active=5, recovery=22 (see attack_charge.tres)
static func _draw_attack_charge(canvas: CanvasItem, frame: int, facing: int, charge_pct: float) -> void:
	var body_color := BODY_COLOR
	var weapon_color := CHARGE_COLOR.lerp(CHARGE_FULL_COLOR, charge_pct)
	_draw_torso(canvas, body_color)
	canvas.draw_line(HIP, _mirror_x(Vector2(-12, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(10, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-8, -8), facing), body_color, LIMB_WIDTH)

	var hand_pos: Vector2
	var weapon_tip: Vector2
	if frame < 10:
		var t = float(frame) / 10.0
		hand_pos = _mirror_x(Vector2(lerpf(-4.0, -2.0, t), lerpf(-32.0, -28.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(lerpf(-4.0, -2.0, t), lerpf(-28.0, -32.0, t)), facing)
	elif frame < 15:
		# Big arc swing down and forward
		var t = float(frame - 10) / 5.0
		var angle := lerpf(-PI / 2.0, PI / 4.0, t)
		hand_pos = _mirror_x(Vector2(cos(angle) * 18.0, sin(angle) * 18.0 - 18.0), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(cos(angle + 0.3) * 36.0, sin(angle + 0.3) * 36.0), facing)
	else:
		var t = clamp(float(frame - 15) / 20.0, 0.0, 1.0)
		hand_pos = _mirror_x(Vector2(lerpf(18.0, 12.0, t), lerpf(-6.0, -6.0, t)), facing)
		weapon_tip = hand_pos + _mirror_x(Vector2(lerpf(36.0, 20.0, t), lerpf(8.0, 4.0, t)), facing)

	canvas.draw_line(Vector2(0, -25), hand_pos, body_color, LIMB_WIDTH)
	canvas.draw_line(hand_pos, weapon_tip, weapon_color, WEAPON_WIDTH + 2.0)
	# Trail particle during active frames
	if frame >= 10 and frame < 15:
		canvas.draw_circle(weapon_tip, 6.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.5))

static func _draw_parry(canvas: CanvasItem, frame: int, facing: int) -> void:
	var body_color := BODY_COLOR
	_draw_torso(canvas, body_color)
	canvas.draw_line(HIP, _mirror_x(Vector2(-8, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(8, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-6, -16), facing), body_color, LIMB_WIDTH)
	var hand := _mirror_x(Vector2(14, -18), facing)
	canvas.draw_line(Vector2(0, -25), hand, body_color, LIMB_WIDTH)
	# Weapon held vertically in front as a guard
	var weapon_tip := hand + Vector2(0, -20)
	canvas.draw_line(hand, weapon_tip, PARRY_COLOR, WEAPON_WIDTH + 1.5)
	# Parry aura — pulses during active window
	var pulse := sin(frame * 0.6) * 0.5 + 0.5
	var aura_color := Color(PARRY_COLOR.r, PARRY_COLOR.g, PARRY_COLOR.b, 0.25 + pulse * 0.3)
	canvas.draw_arc(Vector2(0, -16), 28.0, -PI * 0.75, PI * 0.25, 24, aura_color, 2.0)

static func _draw_hit(canvas: CanvasItem, frame: int, facing: int) -> void:
	var body_color := HIT_COLOR.lerp(BODY_COLOR, clamp(frame / 12.0, 0.0, 1.0))
	# Head tilted back
	canvas.draw_circle(HEAD_POS + Vector2(facing * -3, 2), HEAD_RADIUS, body_color)
	canvas.draw_line(NECK + Vector2(facing * -2, 0), HIP, body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(-6, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(10, 30), facing), body_color, LIMB_WIDTH)
	# Arms flailing
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-14, -20), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(8, -22), facing), body_color, LIMB_WIDTH)

static func _draw_parried(canvas: CanvasItem, frame: int, facing: int) -> void:
	var body_color := STUNNED_COLOR
	# Head bowed forward
	canvas.draw_circle(HEAD_POS + Vector2(facing * 2, 4), HEAD_RADIUS, body_color)
	canvas.draw_line(NECK + Vector2(facing * 2, 4), HIP, body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(-6, 32), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(6, 32), facing), body_color, LIMB_WIDTH)
	# Arms hanging
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-10, -2), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(10, -2), facing), body_color, LIMB_WIDTH)
	# Dizzy stars above head
	var t := frame * 0.2
	for i in 3:
		var a := t + i * PI * 2.0 / 3.0
		var p := HEAD_POS + Vector2(cos(a) * 12, -sin(a) * 4 - 4)
		canvas.draw_circle(p, 2.0, Color(1, 1, 0.4, 0.8))

# Crouch: lowered torso, bent legs, weapon held low. Hurtbox is also halved on game side.
static func _draw_crouch(canvas: CanvasItem, _frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	# Lower head and torso
	var head_y := -22
	var hip_y := 8
	canvas.draw_circle(Vector2(0, head_y), HEAD_RADIUS, body_color)
	canvas.draw_line(Vector2(0, head_y + 8), Vector2(0, hip_y), body_color, LIMB_WIDTH)
	# Bent legs (knees out, feet down)
	canvas.draw_line(Vector2(0, hip_y), Vector2(-10, 22), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(-10, 22), Vector2(-12, 32), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(0, hip_y), Vector2(10, 22), body_color, LIMB_WIDTH)
	canvas.draw_line(Vector2(10, 22), Vector2(12, 32), body_color, LIMB_WIDTH)
	# Arms low
	var shoulder := Vector2(0, -8)
	canvas.draw_line(shoulder, _mirror_x(Vector2(-10, 6), facing), body_color, LIMB_WIDTH)
	var hand := _mirror_x(Vector2(12, 4), facing)
	canvas.draw_line(shoulder, hand, body_color, LIMB_WIDTH)
	canvas.draw_line(hand, hand + _mirror_x(Vector2(16, 0), facing), weapon_color, WEAPON_WIDTH)

# Jump: legs tucked, both arms slightly raised.
static func _draw_jump(canvas: CanvasItem, _frame: int, facing: int, body_color: Color, weapon_color: Color) -> void:
	_draw_torso(canvas, body_color)
	# Tucked legs
	canvas.draw_line(HIP, _mirror_x(Vector2(-8, 18), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(_mirror_x(Vector2(-8, 18), facing), _mirror_x(Vector2(-4, 26), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(HIP, _mirror_x(Vector2(8, 18), facing), body_color, LIMB_WIDTH)
	canvas.draw_line(_mirror_x(Vector2(8, 18), facing), _mirror_x(Vector2(4, 26), facing), body_color, LIMB_WIDTH)
	# Arms slightly up for balance
	canvas.draw_line(Vector2(0, -25), _mirror_x(Vector2(-12, -32), facing), body_color, LIMB_WIDTH)
	var hand := _mirror_x(Vector2(10, -16), facing)
	canvas.draw_line(Vector2(0, -25), hand, body_color, LIMB_WIDTH)
	canvas.draw_line(hand, hand + _mirror_x(Vector2(16, -4), facing), weapon_color, WEAPON_WIDTH)

# ─── Rigged pose (PSD-driven layered body parts) ──────────────────────────────
# All joint positions are derived from PSD coordinates (BodySprites.PSD_*) via
# the BodySprites.psd_to_fighter() helper, with x mirrored when facing left.
# Per-state builders override only the joints that move (hands, feet, body tilt);
# everything else stays at the artist-intended rest pose.
class Skeleton:
	extends RefCounted
	# Head/neck (head's anchor sits at neck — the chin-of-head pivot lands here)
	var head_pos: Vector2 = Vector2.ZERO
	var neck: Vector2 = Vector2.ZERO
	# Two separate shoulders (front facing forward, back trailing)
	var shoulder_back: Vector2 = Vector2.ZERO
	var shoulder_front: Vector2 = Vector2.ZERO
	# Two separate hips
	var hip_back: Vector2 = Vector2.ZERO
	var hip_front: Vector2 = Vector2.ZERO
	# Limb endpoints
	var hand_back: Vector2 = Vector2.ZERO
	var hand_front: Vector2 = Vector2.ZERO
	var foot_back: Vector2 = Vector2.ZERO
	var foot_front: Vector2 = Vector2.ZERO
	var weapon_tip: Vector2 = Vector2.ZERO
	# Whole-body rotation (HIT lean-back, PARRIED bow, ROLL tumble). Applied to
	# torso/head/face/accessories; limbs follow because their endpoints are rotated.
	var body_rotation: float = 0.0
	var body_pivot: Vector2 = Vector2.ZERO
	var tint: Color = Color.WHITE
	var show_weapon: bool = true
	# Stashed for the hair sway renderer — hair lag depends on the active state
	# and animation frame, not on the joint values.
	var state: int = 0
	var frame: int = 0

	func rotate_all(angle: float, pivot: Vector2) -> void:
		if absf(angle) < 0.0001:
			return
		head_pos = _rot(head_pos, pivot, angle)
		neck = _rot(neck, pivot, angle)
		shoulder_back = _rot(shoulder_back, pivot, angle)
		shoulder_front = _rot(shoulder_front, pivot, angle)
		hip_back = _rot(hip_back, pivot, angle)
		hip_front = _rot(hip_front, pivot, angle)
		hand_back = _rot(hand_back, pivot, angle)
		hand_front = _rot(hand_front, pivot, angle)
		foot_back = _rot(foot_back, pivot, angle)
		foot_front = _rot(foot_front, pivot, angle)
		weapon_tip = _rot(weapon_tip, pivot, angle)

	static func _rot(p: Vector2, c: Vector2, a: float) -> Vector2:
		return c + (p - c).rotated(a)

static func draw_rigged_pose(
	canvas: CanvasItem,
	sprites: BodySprites,
	state: int,
	frame: int,
	facing: int,
	charge_pct: float,
	flash_color: Color,
	attack_variant: int = 0,
) -> void:
	if sprites == null or sprites.parts.is_empty():
		return
	var skel := _build_skeleton(sprites, state, frame, facing, charge_pct, attack_variant)
	_render_skeleton(canvas, sprites, skel, facing)
	if flash_color.a > 0.0:
		var c: Color = Color(flash_color.r, flash_color.g, flash_color.b, flash_color.a * 0.6)
		canvas.draw_circle(skel.head_pos, 22.0, c)

# PSD anchor → fighter-coord position, with facing flip on X.
static func _psd2f(sprites: BodySprites, p: Vector2, facing: int) -> Vector2:
	var f: Vector2 = sprites.psd_to_fighter(p)
	f.x *= float(facing)
	return f

static func _build_skeleton(sprites: BodySprites, state: int, frame: int, facing: int, charge_pct: float, variant: int) -> Skeleton:
	var s := Skeleton.new()
	s.state = state
	s.frame = frame
	# Default = rest pose straight from PSD-measured joints.
	s.neck = _psd2f(sprites, BodySprites.PSD_NECK, facing)
	s.head_pos = s.neck
	s.shoulder_back = _psd2f(sprites, BodySprites.PSD_SHOULDER_BACK, facing)
	s.shoulder_front = _psd2f(sprites, BodySprites.PSD_SHOULDER_FRONT, facing)
	s.hip_back = _psd2f(sprites, BodySprites.PSD_HIP_BACK, facing)
	s.hip_front = _psd2f(sprites, BodySprites.PSD_HIP_FRONT, facing)
	s.foot_back = _psd2f(sprites, BodySprites.PSD_FOOT_BACK, facing)
	s.foot_front = _psd2f(sprites, BodySprites.PSD_FOOT_FRONT, facing)
	s.hand_back = _psd2f(sprites, BodySprites.PSD_HAND_BACK, facing)
	s.hand_front = _psd2f(sprites, BodySprites.PSD_HAND_FRONT, facing)
	s.weapon_tip = _psd2f(sprites, BodySprites.PSD_WEAPON_TIP, facing)
	s.body_pivot = (s.hip_back + s.hip_front) * 0.5

	match state:
		Fighter.State.IDLE:
			var bob: float = sin(float(frame) * 0.08) * 0.6
			s.head_pos.y += bob
			s.neck.y += bob
		Fighter.State.WALK:
			# Legs scissor; arms swing opposite.
			var phase: float = float(frame) * 0.35
			var swing: float = sin(phase) * 5.0
			s.foot_back.x += swing
			s.foot_front.x -= swing
			s.hand_back.y -= swing * 0.3
			s.hand_front.y += swing * 0.3
		Fighter.State.CROUCH:
			# Sink the upper body — feet stay planted, hands drop.
			var drop: float = 8.0
			s.head_pos.y += drop; s.neck.y += drop
			s.shoulder_back.y += drop * 0.75
			s.shoulder_front.y += drop * 0.75
			s.hand_back.y += drop
			s.hand_front.y += drop
		Fighter.State.JUMP:
			# Hands rise for balance, feet tuck up slightly.
			s.foot_back.y -= 4
			s.foot_front.y -= 4
			s.hand_back.y -= 6
			s.hand_front.y -= 4
		Fighter.State.ROLL:
			# Tumble around the body centre.
			s.body_pivot = (s.hip_back + s.hip_front) * 0.5 + Vector2(0, -10)
			s.body_rotation = float(frame) * 0.4 * float(facing)
			if frame >= 3 and frame < 15:
				s.tint = Color(0.55, 0.95, 1.0)
		Fighter.State.ATTACK_NORMAL:
			_build_attack_normal_rig(s, frame, facing, variant)
		Fighter.State.CHARGING_UP:
			_build_charging_rig(s, frame, facing, charge_pct)
		Fighter.State.ATTACK_CHARGE_T1:
			_build_attack_charge_rig(s, frame, facing, 0.5)
		Fighter.State.ATTACK_CHARGE:
			_build_attack_charge_rig(s, frame, facing, charge_pct)
		Fighter.State.PARRY:
			# 中段の構え (Chūdan no kamae) — sword horizontal pointing at opponent.
			# Sword is in the back arm; off-hand reaches forward to grip the hilt.
			_pose_sword(s, facing, Vector2(6.0, 0.0), Vector2(36.0, -2.0))
			_grip_two_handed(s, facing)
			s.tint = Color(0.85, 1.0, 1.05)
		Fighter.State.HIT:
			s.body_rotation = 0.25 * float(facing)
			var fade: float = clamp(float(frame) / 12.0, 0.0, 1.0)
			s.tint = Color(1.4, 0.6, 0.6).lerp(Color.WHITE, fade)
			s.hand_back.y -= 4; s.hand_front.y -= 4
		Fighter.State.PARRIED:
			s.body_rotation = -0.18 * float(facing)
			s.tint = Color(0.7, 0.7, 0.85)
	# Apply whole-body rotation after per-state joint assignment.
	if absf(s.body_rotation) > 0.0001:
		s.rotate_all(s.body_rotation, s.body_pivot)
	return s

# Set the sword arm (back arm) hand + sword tip from offsets relative to
# shoulder_back. Hand offsets x mirrors with facing; the tip offset is relative
# to shoulder_back too (NOT to the hand), so the sword's world direction is
# always (tip - hand) regardless of arm reach.
static func _pose_sword(s: Skeleton, facing: int, hand_off: Vector2, tip_off: Vector2) -> void:
	s.hand_back = s.shoulder_back + Vector2(hand_off.x * float(facing), hand_off.y)
	s.weapon_tip = s.shoulder_back + Vector2(tip_off.x * float(facing), tip_off.y)

# Off-hand reaches toward the sword grip to imply a two-handed hold. arm_front
# sprite has a fixed length (~18 fighter units after scale); we just orient it.
static func _grip_two_handed(s: Skeleton, facing: int) -> void:
	var to_sword: Vector2 = s.hand_back - s.shoulder_front
	if to_sword.length_squared() < 0.01:
		return
	const ARM_REACH := 16.0
	s.hand_front = s.shoulder_front + to_sword.normalized() * ARM_REACH

# ─── Tachi techniques ──────────────────────────────────────────────────────
# Each variant maps to a real tachi-jutsu kata. Frame budget per attack_normal.tres:
# startup=5, active=3, recovery=12. Hand/tip offsets are relative to shoulder_back
# (the sword arm); x is mirrored with facing inside _pose_sword.
static func _build_attack_normal_rig(s: Skeleton, frame: int, facing: int, variant: int) -> void:
	var hand_off: Vector2
	var tip_off: Vector2
	match variant:
		1:
			# 袈裟切り (Kesa-giri) — diagonal cut from upper-front shoulder to opposite hip.
			# Startup: lift to upper-front 八双 stance; Active: arc down across the body;
			# Recovery: blade ends low on the off-side.
			if frame < 5:
				var t: float = float(frame) / 5.0
				hand_off = Vector2(lerpf(3.0, 6.0, t), lerpf(14.0, -12.0, t))
				tip_off = Vector2(lerpf(-22.0, 12.0, t), lerpf(10.0, -42.0, t))
			elif frame < 8:
				# Diagonal sweep: tip arcs from upper-front through middle to lower-back.
				var t: float = float(frame - 5) / 3.0
				var ang: float = lerpf(-PI * 0.35, PI * 0.95, t)
				hand_off = Vector2(cos(ang) * 12.0 + 2.0, sin(ang) * 14.0 + 2.0)
				tip_off = Vector2(cos(ang - 0.25) * 36.0, sin(ang - 0.25) * 32.0 + 2.0)
			else:
				var t: float = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
				hand_off = Vector2(lerpf(-6.0, 3.0, t), lerpf(18.0, 14.0, t))
				tip_off = Vector2(lerpf(-32.0, -22.0, t), lerpf(28.0, 10.0, t))
		2:
			# 唐竹 (Karatake) — overhead vertical chop straight down the centreline.
			if frame < 5:
				var t: float = float(frame) / 5.0
				hand_off = Vector2(lerpf(3.0, 0.0, t), lerpf(14.0, -22.0, t))
				tip_off = Vector2(lerpf(-22.0, 2.0, t), lerpf(10.0, -54.0, t))
			elif frame < 8:
				# Vertical chop: hand drops to chest, tip swings to forward-low.
				var t: float = float(frame - 5) / 3.0
				hand_off = Vector2(lerpf(0.0, 4.0, t), lerpf(-22.0, 6.0, t))
				tip_off = Vector2(lerpf(2.0, 14.0, t), lerpf(-54.0, 32.0, t))
			else:
				var t: float = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
				hand_off = Vector2(lerpf(4.0, 3.0, t), lerpf(6.0, 14.0, t))
				tip_off = Vector2(lerpf(14.0, -22.0, t), lerpf(32.0, 10.0, t))
		_:
			# 突き (Tsuki) — straight thrust. Pull back to hip, then drive forward in
			# a horizontal line; no rotation through the active window.
			if frame < 5:
				var t: float = float(frame) / 5.0
				hand_off = Vector2(lerpf(3.0, -6.0, t), lerpf(14.0, 4.0, t))
				tip_off = Vector2(lerpf(-22.0, 22.0, t), lerpf(10.0, 4.0, t))
			elif frame < 8:
				hand_off = Vector2(14.0, 4.0)
				tip_off = Vector2(46.0, 4.0)
			else:
				var t: float = clamp(float(frame - 8) / 10.0, 0.0, 1.0)
				hand_off = Vector2(lerpf(14.0, 3.0, t), lerpf(4.0, 14.0, t))
				tip_off = Vector2(lerpf(46.0, -22.0, t), lerpf(4.0, 10.0, t))
	_pose_sword(s, facing, hand_off, tip_off)
	_grip_two_handed(s, facing)

# 八双の構え (Hassō no kamae) windup — sword raised vertically alongside the
# sword-side shoulder, blade pointing straight up. The classic preparation stance
# for both 横一文字 and 大袈裟.
static func _build_charging_rig(s: Skeleton, frame: int, facing: int, charge_pct: float) -> void:
	var t: float = clampf(float(frame) / 10.0, 0.0, 1.0)
	var hand_idle: Vector2 = Vector2(3.0, 14.0)
	var hand_hasso: Vector2 = Vector2(6.0, -8.0)
	var tip_idle: Vector2 = Vector2(-22.0, 10.0)
	var tip_hasso: Vector2 = Vector2(4.0, -42.0)
	_pose_sword(s, facing, hand_idle.lerp(hand_hasso, t), tip_idle.lerp(tip_hasso, t))
	_grip_two_handed(s, facing)
	s.tint = Color(1.0, 0.95, 0.75).lerp(Color(1.0, 0.55, 0.35), charge_pct * t)

# Charge attacks fired from 八双:
#   T1 (≈ 0.5) → 横一文字 (Yoko ichimonji) — fast horizontal cut at neck height.
#   T2 (1.0) → 大袈裟 (Ō-kesa) — full-body diagonal from overhead to opposite hip.
# Frame budget per attack_charge.tres: startup=10, active=5, recovery=22.
static func _build_attack_charge_rig(s: Skeleton, frame: int, facing: int, charge_pct: float) -> void:
	var is_heavy: bool = charge_pct > 0.75
	var hand_off: Vector2
	var tip_off: Vector2
	if frame < 10:
		# Hold Hassō, gather power. Subtle drift up.
		var t: float = float(frame) / 10.0
		hand_off = Vector2(6.0 - t * 1.0, -8.0 - t * 4.0)
		tip_off = Vector2(4.0 - t * 2.0, -42.0 - t * 6.0)
	elif frame < 15:
		var t: float = float(frame - 10) / 5.0
		if is_heavy:
			# 大袈裟 — overhead sweep ending at opposite hip.
			var ang: float = lerpf(-PI * 0.45, PI * 0.9, t)
			hand_off = Vector2(cos(ang) * 14.0 + 2.0, sin(ang) * 20.0)
			tip_off = Vector2(cos(ang - 0.25) * 46.0, sin(ang - 0.25) * 42.0)
		else:
			# 横一文字 — horizontal at neck height.
			hand_off = Vector2(lerpf(6.0, -6.0, t), -8.0)
			tip_off = Vector2(lerpf(40.0, -32.0, t), -8.0)
	else:
		# Recovery — return toward rest.
		var t: float = clamp(float(frame - 15) / 20.0, 0.0, 1.0)
		if is_heavy:
			hand_off = Vector2(lerpf(-4.0, 3.0, t), lerpf(20.0, 14.0, t))
			tip_off = Vector2(lerpf(-32.0, -22.0, t), lerpf(28.0, 10.0, t))
		else:
			hand_off = Vector2(lerpf(-6.0, 3.0, t), lerpf(-8.0, 14.0, t))
			tip_off = Vector2(lerpf(-32.0, -22.0, t), lerpf(-8.0, 10.0, t))
	_pose_sword(s, facing, hand_off, tip_off)
	_grip_two_handed(s, facing)
	s.tint = Color(1.0, 0.95, 0.75).lerp(Color(1.0, 0.55, 0.35), charge_pct)

# ─── Renderer ─────────────────────────────────────────────────────────────
static func _render_skeleton(canvas: CanvasItem, sprites: BodySprites, skel: Skeleton, facing: int) -> void:
	for part in sprites.parts:
		match part.kind:
			"limb":
				_render_limb(canvas, sprites, part, skel, facing)
			"static":
				_render_static(canvas, sprites, part, skel, facing)
			"head_child":
				_render_head_child(canvas, sprites, part, skel, facing)
			# "skip": unrecognised layer, drop silently

static func _render_limb(canvas: CanvasItem, sprites: BodySprites, part, skel: Skeleton, facing: int) -> void:
	var start: Vector2
	var end: Vector2
	match part.name:
		"arm_back":
			start = skel.shoulder_back; end = skel.hand_back
		"arm_front":
			start = skel.shoulder_front; end = skel.hand_front
		"leg_back":
			start = skel.hip_back; end = skel.foot_back
		"leg_front":
			start = skel.hip_front; end = skel.foot_front
		"sword":
			if not skel.show_weapon:
				return
			# Sword is gripped by the back arm (character's right hand).
			start = skel.hand_back; end = skel.weapon_tip
		_:
			return
	var d: Vector2 = end - start
	if d.length_squared() < 0.0001:
		return
	var dir_angle: float = atan2(d.y, d.x)
	# Mirror-compensated rotation (see body_sprites.gd notes).
	var nat: float = part.natural_angle if facing == 1 else (PI - part.natural_angle)
	var rot: float = dir_angle - nat
	_draw_part(canvas, part, sprites.scale, start, rot, facing, skel.tint)

static func _render_static(canvas: CanvasItem, sprites: BodySprites, part, skel: Skeleton, facing: int) -> void:
	# Anchor: the PSD joint this part attaches to.
	var world_pos: Vector2
	if part.pivot_psd == BodySprites.PSD_NECK:
		world_pos = skel.neck
	else:
		# Generic body-attached anchor — convert and apply body rotation.
		var local: Vector2 = sprites.psd_to_fighter(part.pivot_psd)
		local.x *= float(facing)
		world_pos = (local - skel.body_pivot).rotated(skel.body_rotation) + skel.body_pivot
	var rot: float = skel.body_rotation
	if part.is_chest_jiggle:
		rot += _chest_sway(skel, facing)
	_draw_part(canvas, part, sprites.scale, world_pos, rot, facing, skel.tint)

# Chest jiggle: a softer, lower-frequency secondary sway than hair. Anchored at
# top-centre of the chest layer so rotation reads as the chest pendulum-ing.
static func _chest_sway(skel: Skeleton, facing: int) -> float:
	var f: float = float(skel.frame)
	match skel.state:
		Fighter.State.IDLE:
			return sin(f * 0.06) * 0.012
		Fighter.State.WALK:
			# Bounce twice as fast as the leg swing — each step jolts the chest.
			return sin(f * 0.70) * 0.07
		Fighter.State.CROUCH:
			# Settle forward as the upper body drops, then hold steady.
			var t: float = clampf(f / 6.0, 0.0, 1.0)
			return 0.04 * float(facing) * t
		Fighter.State.JUMP:
			# Trails up briefly when the character lifts off.
			return -0.10 * float(facing) * clampf(1.0 - f / 12.0, 0.0, 1.0)
		Fighter.State.ROLL:
			return sin(f * 0.50) * 0.18 * float(facing)
		Fighter.State.ATTACK_NORMAL, Fighter.State.ATTACK_CHARGE_T1, Fighter.State.ATTACK_CHARGE:
			# Lag-then-snap with the swing, smaller than hair so it's a secondary read.
			if f < 5.0:
				return -0.05 * float(facing) * (f / 5.0)
			elif f < 10.0:
				return 0.10 * float(facing) * (1.0 - (f - 5.0) / 5.0)
			else:
				return 0.04 * float(facing) * exp(-(f - 10.0) / 8.0)
		Fighter.State.CHARGING_UP:
			var t: float = clampf(f / 10.0, 0.0, 1.0)
			return -0.05 * float(facing) * t
		Fighter.State.HIT:
			# Big initial jolt that oscillates as it decays.
			return sin(f * 0.55) * 0.22 * exp(-f / 10.0)
		Fighter.State.PARRIED:
			return 0.08 * float(facing)
	return 0.0

static func _render_head_child(canvas: CanvasItem, sprites: BodySprites, part, skel: Skeleton, facing: int) -> void:
	# Offset from the head's neck-anchor in PSD coords → fighter coords → rotated.
	var offset_psd: Vector2 = part.pivot_psd - BodySprites.PSD_NECK
	var offset_fighter: Vector2 = Vector2(offset_psd.x * sprites.scale * float(facing), offset_psd.y * sprites.scale)
	var rotated: Vector2 = offset_fighter.rotated(skel.body_rotation)
	var world_pos: Vector2 = skel.neck + rotated
	# Hair gets an extra sway rotation around its attachment point on top of the
	# body rotation. Non-hair head children (eyes, mouth, brows…) render unchanged.
	var rot: float = skel.body_rotation
	if part.is_hair:
		rot += _hair_sway(part, skel, facing)
	_draw_part(canvas, part, sprites.scale, world_pos, rot, facing, skel.tint)

# Per-strand sway angle. Combines a state-driven base swing with a per-strand
# sine oscillation (different phase per strand → bangs don't move in lock-step).
# Returned angle is positive = strand swings clockwise in screen space.
static func _hair_sway(part, skel: Skeleton, facing: int) -> float:
	var f: float = float(skel.frame)
	var base: float = _hair_sway_base(skel.state, f, facing)
	# Always-on subtle oscillation so hair is never perfectly still — keeps the
	# character from looking like a frozen sprite during idle.
	var stagger: float = sin(f * 0.13 + part.hair_phase) * 0.025
	return (base + stagger) * part.hair_amplitude

static func _hair_sway_base(state: int, f: float, facing: int) -> float:
	match state:
		Fighter.State.IDLE:
			return sin(f * 0.07) * 0.025
		Fighter.State.WALK:
			# Sway in time with the walk-cycle leg swing. Hair lags ~π/2 behind the
			# step so it reads as inertia, not as following the feet exactly.
			return sin(f * 0.35 - PI * 0.5) * 0.14
		Fighter.State.CROUCH:
			# Settle forward as the head drops, then hold.
			var t: float = clampf(f / 6.0, 0.0, 1.0)
			return 0.06 * float(facing) * t
		Fighter.State.JUMP:
			# Lifts upward as the character ascends — hair angles backward (opposite of facing).
			return -0.20 * float(facing)
		Fighter.State.ROLL:
			# Hair whips with the tumble; large amplitude with the rotation direction.
			return sin(f * 0.45) * 0.35 * float(facing)
		Fighter.State.ATTACK_NORMAL, Fighter.State.ATTACK_CHARGE_T1, Fighter.State.ATTACK_CHARGE:
			# Hair lags behind the swing. Push back during startup, snap forward
			# during the active window, then settle.
			if f < 5.0:
				return -0.10 * float(facing) * (f / 5.0)
			elif f < 10.0:
				return 0.20 * float(facing) * (1.0 - (f - 5.0) / 5.0)
			else:
				return 0.08 * float(facing) * exp(-(f - 10.0) / 6.0)
		Fighter.State.CHARGING_UP:
			# Gathering motion — hair drifts back/up as the sword raises.
			var t: float = clampf(f / 10.0, 0.0, 1.0)
			return -0.12 * float(facing) * t + sin(f * 0.18) * 0.015
		Fighter.State.PARRY:
			return 0.04 * float(facing)
		Fighter.State.HIT:
			# Violent whip in the direction of the hit, decaying.
			return 0.4 * float(facing) * exp(-f / 8.0)
		Fighter.State.PARRIED:
			# Bow forward — hair drops in the facing direction.
			return 0.18 * float(facing)
	return 0.0

# Common draw path: anchors part.pivot_psd (in texture pixels) at world_pos,
# applies rotation + facing-mirror, tints with `tint`.
static func _draw_part(canvas: CanvasItem, part, scale: float, world_pos: Vector2, rotation: float, facing: int, tint: Color) -> void:
	if part.texture == null:
		return
	var t := Transform2D(rotation, Vector2(scale * float(facing), scale), 0.0, world_pos)
	canvas.draw_set_transform_matrix(t)
	var pivot_px: Vector2 = part.pivot_psd - part.psd_origin
	canvas.draw_texture(part.texture, -pivot_px, tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

# ─── Sprite-based pose (single full-character texture) ─────────────────────────
# Used when a Fighter has sprite_texture assigned. State is expressed through
# transform (lean, squish, tumble) and modulate tint — no per-limb animation.
# Feet sit at the fighter origin (y=+32 line is the ground level of stick figure).
const SPRITE_TARGET_HEIGHT := 110.0
const SPRITE_FEET_Y := 32.0

static func draw_sprite_pose(
	canvas: CanvasItem,
	texture: Texture2D,
	state: int,
	frame: int,
	facing: int,
	charge_pct: float,
	flash_color: Color,
) -> void:
	var tex_size: Vector2 = texture.get_size()
	var base_scale: float = SPRITE_TARGET_HEIGHT / tex_size.y
	var scale_x: float = base_scale
	var scale_y: float = base_scale
	var draw_pos: Vector2 = Vector2(0, SPRITE_FEET_Y)  # bottom-center of sprite
	var rotation: float = 0.0
	var tint: Color = Color.WHITE
	var pivot_center: bool = false  # true = pivot from body center (for tumble)

	match state:
		Fighter.State.IDLE:
			draw_pos.y += sin(float(frame) * 0.08) * 0.8
		Fighter.State.WALK:
			draw_pos.y += abs(sin(float(frame) * 0.35)) * 2.0
		Fighter.State.CROUCH:
			scale_y = base_scale * 0.7
		Fighter.State.JUMP:
			pass
		Fighter.State.ROLL:
			# Tumble: rotate around body center, in facing direction
			pivot_center = true
			rotation = float(frame) * 0.4 * facing
			# Cyan tint during iframes (frames 3..14)
			if frame >= 3 and frame < 15:
				tint = Color(0.55, 0.95, 1.0)
		Fighter.State.ATTACK_NORMAL:
			# Lean forward briefly during the active window
			if frame >= 4 and frame < 9:
				rotation = -0.18 * facing
				draw_pos.x += 8.0 * facing
		Fighter.State.CHARGING_UP:
			# Warm up to orange as charge fills
			tint = Color(1.0, 0.95, 0.75).lerp(Color(1.0, 0.55, 0.35), charge_pct)
			# Slight upward lift as windup
			var t: float = clampf(float(frame) / 10.0, 0.0, 1.0)
			draw_pos.y -= 2.0 * t
		Fighter.State.ATTACK_CHARGE_T1, Fighter.State.ATTACK_CHARGE:
			tint = Color(1.0, 0.75, 0.35) if state == Fighter.State.ATTACK_CHARGE else Color(1.0, 0.85, 0.45)
			# Big lunge during the swing
			if frame >= 10 and frame < 15:
				rotation = -0.28 * facing
				draw_pos.x += 12.0 * facing
		Fighter.State.PARRY:
			tint = Color(0.7, 0.95, 1.05)
			# Subtle defensive back-lean
			rotation = 0.08 * facing
		Fighter.State.HIT:
			# Red flash that fades, head tipped back
			var fade: float = clamp(float(frame) / 12.0, 0.0, 1.0)
			tint = Color(1.4, 0.6, 0.6).lerp(Color.WHITE, fade)
			rotation = 0.2 * facing
			draw_pos.x -= 5.0 * facing
		Fighter.State.PARRIED:
			tint = Color(0.7, 0.7, 0.85)
			rotation = 0.15 * facing  # bow forward
			draw_pos.x -= 2.0 * facing

	# Build the draw transform. Negative scale_x via facing handles the mirror.
	var transform: Transform2D = Transform2D(rotation, Vector2(scale_x * facing, scale_y), 0.0, draw_pos)
	canvas.draw_set_transform_matrix(transform)
	# In local space, place the sprite so its bottom-center sits at origin.
	# If pivoting from center (roll), raise the pivot to the body midpoint.
	var pivot_y: float = -tex_size.y if not pivot_center else -tex_size.y * 0.5
	canvas.draw_texture(texture, Vector2(-tex_size.x * 0.5, pivot_y), tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

	if flash_color.a > 0.0:
		canvas.draw_circle(Vector2(0, -55), 32.0, Color(flash_color.r, flash_color.g, flash_color.b, flash_color.a * 0.6))

# Roll: tumbling ball with motion blur dots. Color shifts cyan during iframes.
static func _draw_roll(canvas: CanvasItem, frame: int, facing: int, body_color: Color) -> void:
	# Cyan tint during iframes (active window) — visual signal of invulnerability.
	# Game-side: hurtbox is disabled while is_active_at(frame) is true.
	var roll_t := float(frame) * 0.7
	var rotation_pivot := Vector2(0, -8)
	# Use a circle as the rolling body
	canvas.draw_circle(rotation_pivot, 14.0, body_color)
	# Indicator line showing rotation direction
	var dir := Vector2(cos(roll_t), sin(roll_t)) * 10.0
	canvas.draw_line(rotation_pivot, rotation_pivot + dir, Color(0.08, 0.08, 0.1, 1), 2.5)
	# Motion trail
	for i in 3:
		var trail_pos := rotation_pivot + Vector2(-facing * (i + 1) * 6, 0)
		var trail_alpha := 0.5 - i * 0.15
		canvas.draw_circle(trail_pos, 8.0 - i * 1.5, Color(body_color.r, body_color.g, body_color.b, trail_alpha))
	# Iframe ring (cyan flash for 12 active frames startup=3 → frames 3..14 are invuln)
	if frame >= 3 and frame < 15:
		canvas.draw_arc(rotation_pivot, 18.0, 0, TAU, 32, Color(0.45, 0.95, 1.0, 0.6), 2.0)
