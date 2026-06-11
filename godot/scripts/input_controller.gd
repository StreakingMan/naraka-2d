class_name InputController
extends RefCounted

# ActionIntent dict shape:
#   move: int      (-1, 0, +1)
#   normal: bool   (just pressed)
#   charge_hold: bool   (held)
#   charge_release: bool (just released)
#   parry: bool    (just pressed)
#   jump: bool     (just pressed)
#   crouch_hold: bool   (held)
#   dodge: bool    (just pressed)

func tick(_fighter) -> Dictionary:
	# J is bound to attack_charge. From IDLE/WALK, the player goes through
	# CHARGING_UP and the tap-vs-hold duration decides between ATTACK_NORMAL and
	# the charge tiers (Fighter._resolve_charge_release).
	# From CROUCH/JUMP, there's no charge path — the just-pressed `normal` intent
	# below fires an immediate ATTACK_NORMAL directly out of those states.
	# (On IDLE/WALK these intents collide for one frame; `holding_charge` is
	# checked first in Fighter._resolve_state so the charge path still wins.)
	return {
		"move": int(Input.is_action_pressed(&"move_right")) - int(Input.is_action_pressed(&"move_left")),
		"normal": Input.is_action_just_pressed(&"attack_charge"),
		"charge_hold": Input.is_action_pressed(&"attack_charge"),
		"charge_release": Input.is_action_just_released(&"attack_charge"),
		"parry": Input.is_action_just_pressed(&"parry"),
		"jump": Input.is_action_just_pressed(&"jump"),
		"crouch_hold": Input.is_action_pressed(&"crouch"),
		"dodge": Input.is_action_just_pressed(&"dodge"),
	}
