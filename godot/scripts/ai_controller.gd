class_name AIController
extends RefCounted

enum Mode { DUMMY, TRAINER, COMBAT }

# ============================================================
# Trainer schedule (DEMO mode that cycles the triangle for practice)
# ============================================================
const CYCLE_LENGTH := 240
# New triangle (correct Naraka mechanics):
#   Parry catches Charge   → counter: parry when trainer charges
#   Normal breaks Parry    → counter: J when trainer parries
#   Charge punishes Normal → counter: hold J to charge when trainer normals
const SCHEDULE := [
	# Phase 1: Trainer CHARGES — player should PARRY (K) to catch it
	{"start": 0, "end": 50, "action": "charge_hold"},
	{"start": 50, "end": 51, "action": "charge_release"},
	{"start": 51, "end": 90, "action": "idle"},
	# Phase 2: Trainer PARRIES — player should normal-attack (tap J) to break it
	{"start": 90, "end": 95, "action": "parry"},
	{"start": 95, "end": 150, "action": "idle"},
	# Phase 3: Trainer NORMAL-ATTACKS — player should CHARGE (hold J) to punish
	{"start": 150, "end": 155, "action": "normal"},
	{"start": 155, "end": 240, "action": "idle"},
]

# ============================================================
# Combat AI tuning constants
# ============================================================
const ATTACK_RANGE := 95.0
const APPROACH_RANGE := 80.0
const RETREAT_MIN := 60.0
const FAR_RANGE := 240.0

# Reaction delay (frames): higher = AI feels more human / beatable
const REACT_TO_CHARGE := 18   # 300 ms — punish enemy charge with normal
const REACT_TO_INCOMING := 10  # 167 ms — defensive roll on incoming swing
const DECISION_COOLDOWN_MIN := 20
const DECISION_COOLDOWN_MAX := 40

# ============================================================
# State
# ============================================================
var mode: int = Mode.DUMMY
var _cycle_frame: int = 0
var _was_holding_charge: bool = false

var _decision_cooldown: int = 0
var _pending_action: String = ""   # "normal" | "charge" | "parry" | "roll_back" | ""
var _pending_delay: int = 0
var _hold_charge_until: int = 0    # frame counter for charge duration
var _charge_frames_held: int = 0
var _move_dir: int = 0             # -1, 0, +1 for current move intent
var _rng: RandomNumberGenerator

func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func set_mode(m: int) -> void:
	mode = m
	_cycle_frame = 0
	_was_holding_charge = false
	_decision_cooldown = 0
	_pending_action = ""
	_pending_delay = 0
	_hold_charge_until = 0
	_charge_frames_held = 0
	_move_dir = 0

func tick(fighter) -> Dictionary:
	var intent := {
		"move": 0, "normal": false, "charge_hold": false,
		"charge_release": false, "parry": false,
		"jump": false, "crouch_hold": false, "dodge": false,
	}
	match mode:
		Mode.DUMMY:
			pass
		Mode.TRAINER:
			_apply_trainer_schedule(intent)
			# Maintain attack range so practice swings actually land on the player.
			_trainer_maintain_distance(intent, fighter)
			_cycle_frame = (_cycle_frame + 1) % CYCLE_LENGTH
		Mode.COMBAT:
			_combat_tick(intent, fighter)
	return intent

# Walks the trainer toward / away from the player to maintain ~75 px gap (just inside
# normal attack range). Without this, the player wanders out of range and the trainer's
# scheduled swings whiff into thin air, making parry practice impossible.
func _trainer_maintain_distance(intent: Dictionary, fighter) -> void:
	if fighter == null or fighter.opponent == null:
		return
	# Don't move while attacking / parrying / stunned — would conflict with the swing.
	if not (fighter.state == Fighter.State.IDLE or fighter.state == Fighter.State.WALK):
		return
	var dx: float = fighter.opponent.global_position.x - fighter.global_position.x
	var dist: float = abs(dx)
	var toward_opp: int = 1 if dx > 0 else -1
	# Must stay strictly INSIDE normal-attack reach (~74 px), or the trainer's J swings
	# whiff and the player never has anything to parry. 60 gives margin.
	var target_dist := 60.0
	var threshold := 8.0
	if dist > target_dist + threshold:
		intent.move = toward_opp
	elif dist < target_dist - threshold:
		intent.move = -toward_opp

# ------------------------------------------------------------
# Trainer mode
# ------------------------------------------------------------
func _apply_trainer_schedule(intent: Dictionary) -> void:
	var action := "idle"
	for entry in SCHEDULE:
		if _cycle_frame >= entry.start and _cycle_frame < entry.end:
			action = entry.action
			break
	match action:
		"normal":
			intent.normal = true
		"charge_hold":
			intent.charge_hold = true
			_was_holding_charge = true
		"charge_release":
			intent.charge_release = _was_holding_charge
			_was_holding_charge = false
		"parry":
			intent.parry = true
		_:
			if _was_holding_charge:
				intent.charge_release = true
				_was_holding_charge = false

# ------------------------------------------------------------
# COMBAT mode — reactive AI
#
# Strategy (Naraka triangle):
#   - Maintain distance ~80 px (just within normal attack range)
#   - Player begins to CHARGE_UP → AI raises PARRY (parry catches charge)
#   - Player committed to a heavy CHARGE swing → AI rolls back as a fallback
#   - Otherwise: throttled random pokes (mostly normal, occasional charge / parry)
#
# Constraints:
#   - Does NOT reactively parry normal attacks (5f startup — humans can't either)
#   - Reaction delays make the AI feel human-paced and beatable
# ------------------------------------------------------------
func _combat_tick(intent: Dictionary, fighter) -> void:
	if fighter == null or fighter.opponent == null:
		return
	var me: Fighter = fighter
	var opp: Fighter = fighter.opponent as Fighter

	# If we're stunned / locked, just maintain the held charge if any.
	if _is_locked_state(me.state):
		_pending_action = ""
		_pending_delay = 0
		_charge_frames_held = 0
		return

	var dx: float = opp.global_position.x - me.global_position.x
	var dist: float = abs(dx)
	var toward_opp: int = 1 if dx > 0 else -1

	# 1) Emergency reactive layer (overrides current pending action)
	_check_reactive_responses(me, opp, dist)

	# 2) Maintain ongoing charge hold if we've committed to charging
	if _hold_charge_until > 0:
		_hold_charge_until -= 1
		_charge_frames_held += 1
		intent.charge_hold = true
		if _hold_charge_until == 0:
			intent.charge_release = true
			_charge_frames_held = 0
		return  # don't move while charging

	# 3) Fire pending queued action when delay reaches 0
	if _pending_action != "":
		if _pending_delay > 0:
			_pending_delay -= 1
		else:
			_execute_pending(intent, me, toward_opp)
			return

	# 4) Decision tick (throttled)
	if _decision_cooldown > 0:
		_decision_cooldown -= 1
	else:
		_decide(me, opp, dist, toward_opp)
		_decision_cooldown = _rng.randi_range(DECISION_COOLDOWN_MIN, DECISION_COOLDOWN_MAX)

	# 5) Movement: maintain target distance
	_apply_movement(intent, me, dist, toward_opp)

# Look for player actions that demand an immediate AI response.
func _check_reactive_responses(me: Fighter, opp: Fighter, dist: float) -> void:
	# Player charging up → parry to catch it (Parry beats Charge in the new triangle)
	if opp.state == Fighter.State.CHARGING_UP and dist < ATTACK_RANGE + 30.0:
		if _pending_action != "parry":
			_pending_action = "parry"
			_pending_delay = REACT_TO_CHARGE
		return

	# Player already swinging a heavy charge and we're not parry-ready → roll back as fallback
	var opp_in_charge_swing := (
		opp.state == Fighter.State.ATTACK_CHARGE
		or opp.state == Fighter.State.ATTACK_CHARGE_T1
	) and opp.state_frame < opp.attack_charge_data.startup
	if opp_in_charge_swing and dist < ATTACK_RANGE + 20.0:
		if _pending_action != "roll_back":
			_pending_action = "roll_back"
			_pending_delay = REACT_TO_INCOMING
		return

# Decide a fresh action when nothing else is pending.
func _decide(me: Fighter, opp: Fighter, dist: float, toward_opp: int) -> void:
	# Far: just approach
	if dist > FAR_RANGE:
		_move_dir = toward_opp
		return

	# In attack range — pick an action by rolling against weights
	if dist < ATTACK_RANGE:
		var r: float = _rng.randf()
		if r < 0.45:
			# Normal poke
			_pending_action = "normal"
			_pending_delay = _rng.randi_range(3, 8)
		elif r < 0.62:
			# Stand still — bait
			_move_dir = 0
		elif r < 0.78:
			# Throw a short charge (tier 1)
			_pending_action = "charge_t1"
			_pending_delay = _rng.randi_range(2, 6)
		elif r < 0.88:
			# Defensive parry (sometimes catches a player normal)
			_pending_action = "parry"
			_pending_delay = _rng.randi_range(2, 5)
		elif r < 0.95:
			# Back-off briefly
			_move_dir = -toward_opp
		else:
			# Occasional roll to reposition
			_pending_action = "roll_back"
			_pending_delay = 0
	else:
		# Mid-range: close in
		_move_dir = toward_opp

# Execute the queued action by setting the right intent flags.
func _execute_pending(intent: Dictionary, me: Fighter, toward_opp: int) -> void:
	match _pending_action:
		"normal":
			intent.normal = true
		"charge_t1":
			# Hold charge for ~30 frames → tier-1 release
			_hold_charge_until = 30
			intent.charge_hold = true
		"charge_t2":
			_hold_charge_until = 60
			intent.charge_hold = true
		"parry":
			intent.parry = true
		"roll_back":
			# Roll away by holding away-direction then triggering dodge
			intent.move = -toward_opp
			intent.dodge = true
		_:
			pass
	_pending_action = ""
	_pending_delay = 0

# Movement based on _move_dir, but also drive distance maintenance.
func _apply_movement(intent: Dictionary, me: Fighter, dist: float, toward_opp: int) -> void:
	# Override _move_dir if we're too close or too far for our taste
	if dist < RETREAT_MIN:
		intent.move = -toward_opp
	elif dist > APPROACH_RANGE + 30.0:
		intent.move = toward_opp
	else:
		intent.move = _move_dir

func _is_locked_state(s: int) -> bool:
	return (
		s == Fighter.State.ATTACK_NORMAL
		or s == Fighter.State.ATTACK_CHARGE_T1
		or s == Fighter.State.ATTACK_CHARGE
		or s == Fighter.State.PARRY
		or s == Fighter.State.HIT
		or s == Fighter.State.PARRIED
		or s == Fighter.State.ROLL
		or s == Fighter.State.JUMP
	)

func mode_label() -> String:
	match mode:
		Mode.DUMMY: return "Dummy"
		Mode.TRAINER: return "Trainer"
		Mode.COMBAT: return "Combat AI"
	return "?"
