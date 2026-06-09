class_name CombatResolver
extends RefCounted

enum Outcome {
	NO_HIT,
	NORMAL_HIT,
	CHARGE_HIT,
	CHARGE_PUNISHES_NORMAL,   # Charge attack hits a foe mid-normal-swing → big damage + stun
	NORMAL_GRAZES_CHARGE,     # Normal hits a foe in charge stance → reduced damage, no interrupt
	PARRY_SUCCESS,            # Parry catches incoming Charge → attacker stunned
	PARRY_BROKEN,             # Normal interrupts a Parry stance → defender stunned
}

static func outcome_name(o: int) -> String:
	match o:
		Outcome.NO_HIT: return "NO_HIT"
		Outcome.NORMAL_HIT: return "NORMAL_HIT"
		Outcome.CHARGE_HIT: return "CHARGE_HIT"
		Outcome.CHARGE_PUNISHES_NORMAL: return "CHARGE_PUNISHES_NORMAL"
		Outcome.NORMAL_GRAZES_CHARGE: return "NORMAL_GRAZES_CHARGE"
		Outcome.PARRY_SUCCESS: return "PARRY_SUCCESS"
		Outcome.PARRY_BROKEN: return "PARRY_BROKEN"
	return "?"

# The Naraka triangle:
#   Parry  catches  Charge   (parry active + charge attack → PARRY_SUCCESS — attacker stunned)
#   Normal breaks   Parry    (normal hits parry stance → PARRY_BROKEN — defender stunned)
#   Charge punishes Normal   (charge hits normal-swinging foe → CHARGE_PUNISHES_NORMAL — defender stunned)
#
# Side rule:
#   Normal vs Charge stance → NORMAL_GRAZES_CHARGE (reduced damage, defender NOT interrupted)
#
# Args:
#   attacker_action — attacker.state (ATTACK_NORMAL or ATTACK_CHARGE; T1 is normalized to CHARGE by caller)
#   defender_state — defender.state at hit time
#   parry_active   — true if defender is in PARRY active window
#   in_charge_stance — true if defender is in CHARGING_UP / ATTACK_CHARGE_T1 / ATTACK_CHARGE
static func resolve(
	attacker_action: int,
	defender_state: int,
	parry_active: bool,
	in_charge_stance: bool,
) -> int:
	# Parry interactions (defender is mid-parry-window)
	if defender_state == Fighter.State.PARRY and parry_active:
		if attacker_action == Fighter.State.ATTACK_CHARGE:
			return Outcome.PARRY_SUCCESS         # Parry catches Charge — attacker stunned
		if attacker_action == Fighter.State.ATTACK_NORMAL:
			return Outcome.PARRY_BROKEN          # Normal breaks Parry — defender stunned

	# Charge punishes a foe caught mid-normal-swing
	if attacker_action == Fighter.State.ATTACK_CHARGE and defender_state == Fighter.State.ATTACK_NORMAL:
		return Outcome.CHARGE_PUNISHES_NORMAL

	# Normal grazes a charging foe (reduced damage, defender keeps charging)
	if attacker_action == Fighter.State.ATTACK_NORMAL and in_charge_stance:
		return Outcome.NORMAL_GRAZES_CHARGE

	# Default by attacker action
	if attacker_action == Fighter.State.ATTACK_CHARGE:
		return Outcome.CHARGE_HIT
	if attacker_action == Fighter.State.ATTACK_NORMAL:
		return Outcome.NORMAL_HIT

	return Outcome.NO_HIT
