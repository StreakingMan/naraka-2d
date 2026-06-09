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
