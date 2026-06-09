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
	# J/K are both bound to attack_charge. Pressing & releasing within tier-1 threshold
	# fires a normal attack via the charge release path (Fighter._resolve_charge_release).
	# So the player never produces a `normal` intent directly — that field stays false
	# for player input. (AI controllers still use it for instant-attack convenience.)
	return {
		"move": int(Input.is_action_pressed(&"move_right")) - int(Input.is_action_pressed(&"move_left")),
		"normal": false,
		"charge_hold": Input.is_action_pressed(&"attack_charge"),
		"charge_release": Input.is_action_just_released(&"attack_charge"),
		"parry": Input.is_action_just_pressed(&"parry"),
		"jump": Input.is_action_just_pressed(&"jump"),
		"crouch_hold": Input.is_action_pressed(&"crouch"),
		"dodge": Input.is_action_just_pressed(&"dodge"),
	}
