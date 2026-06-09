class_name DebugOverlay
extends Node2D

var fighters: Array[Fighter] = []
var enabled: bool = true   # debug overlay starts ON so users can see hitboxes immediately

const HITBOX_COLOR := Color(1, 0.3, 0.3, 0.4)
const HITBOX_BORDER := Color(1, 0.4, 0.4, 1)
const HURTBOX_COLOR := Color(0.3, 1, 0.4, 0.18)
const HURTBOX_BORDER := Color(0.4, 1, 0.4, 1)
const PARRY_COLOR := Color(0.4, 0.9, 1, 0.35)
const PARRY_BORDER := Color(0.5, 0.95, 1, 1)
const STATE_TEXT := Color(1, 1, 0.7, 0.95)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_debug"):
		enabled = not enabled
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	for f in fighters:
		_draw_fighter_debug(f)

func _draw_fighter_debug(f: Fighter) -> void:
	if f == null:
		return
	# Hurtbox (always-on, green; parry-active = cyan)
	var hurt_rect: Rect2 = f.get_hurtbox_rect()
	hurt_rect.position += f.global_position
	var is_parrying: bool = f.is_parry_active()
	draw_rect(hurt_rect, PARRY_COLOR if is_parrying else HURTBOX_COLOR)
	draw_rect(hurt_rect, PARRY_BORDER if is_parrying else HURTBOX_BORDER, false, 1.0)

	# Hitbox (red, when active)
	if f.is_hitbox_active():
		var hit_rect: Rect2 = f.get_hitbox_rect()
		hit_rect.position += f.global_position
		draw_rect(hit_rect, HITBOX_COLOR)
		draw_rect(hit_rect, HITBOX_BORDER, false, 1.0)

	# State + frame text above hurtbox
	var font := ThemeDB.fallback_font
	var size := 11
	var state_name := _state_name(f.state)
	var label := "%s  f=%d  hp=%d" % [state_name, f.state_frame, f.hp]
	if f.hitstop_frames > 0:
		label += "  HS=%d" % f.hitstop_frames
	if f.state == Fighter.State.CHARGING_UP:
		label += "  charge=%d" % f.charge_frames
	if f.is_invulnerable():
		label += "  iFRAMES"
	draw_string(font, f.global_position + Vector2(-60, -90), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, STATE_TEXT)

func _state_name(s: int) -> String:
	match s:
		Fighter.State.IDLE: return "IDLE"
		Fighter.State.WALK: return "WALK"
		Fighter.State.CROUCH: return "CROUCH"
		Fighter.State.JUMP: return "JUMP"
		Fighter.State.ROLL: return "ROLL"
		Fighter.State.ATTACK_NORMAL: return "ATK_N"
		Fighter.State.CHARGING_UP: return "CHARGING"
		Fighter.State.ATTACK_CHARGE_T1: return "ATK_C1"
		Fighter.State.ATTACK_CHARGE: return "ATK_C2"
		Fighter.State.PARRY: return "PARRY"
		Fighter.State.HIT: return "HIT"
		Fighter.State.PARRIED: return "PARRIED"
	return "?"
