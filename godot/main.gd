extends Node2D

const GROUND_Y := 280.0
const SPAWN_X_OFFSET := 220.0

@onready var hud: HUD = $HUD
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var camera: Camera2D = $Camera2D

var player: Fighter
var enemy: Fighter
var ai: AIController

func _ready() -> void:
	_spawn_fighters()
	_wire_hud_and_debug()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"reset_match"):
		_reset_positions()
	if Input.is_action_just_pressed(&"toggle_ai"):
		# Cycle DUMMY → TRAINER → COMBAT → DUMMY
		ai.set_mode((ai.mode + 1) % 3)
	queue_redraw()

func _draw() -> void:
	# Ground line
	var width := get_viewport_rect().size.x
	draw_line(Vector2(-width, GROUND_Y), Vector2(width * 2, GROUND_Y), Color(0.3, 0.3, 0.4, 1), 2.0)
	# Faint dashed center
	var mid := width * 0.5
	for i in 20:
		var x := mid - 200 + i * 20
		draw_line(Vector2(x, GROUND_Y - 6), Vector2(x + 8, GROUND_Y - 6), Color(0.2, 0.2, 0.3, 1), 1.0)

func _spawn_fighters() -> void:
	var attack_n: AttackFrameData = load("res://data/attack_normal.tres")
	var attack_c1: AttackFrameData = load("res://data/attack_charge_t1.tres")
	var attack_c: AttackFrameData = load("res://data/attack_charge.tres")
	var parry_d: AttackFrameData = load("res://data/parry.tres")
	var roll_d: AttackFrameData = load("res://data/roll.tres")
	var hit_n: ReactionFrameData = load("res://data/hit_normal.tres")
	var hit_c: ReactionFrameData = load("res://data/hit_charge.tres")
	var hit_p: ReactionFrameData = load("res://data/hit_parried.tres")

	player = _make_fighter(true, "Player", attack_n, attack_c1, attack_c, parry_d, roll_d, hit_n, hit_c, hit_p)
	enemy = _make_fighter(false, "Trainer", attack_n, attack_c1, attack_c, parry_d, roll_d, hit_n, hit_c, hit_p)

	add_child(player)
	add_child(enemy)

	player.controller = InputController.new()
	ai = AIController.new()
	ai.set_mode(AIController.Mode.DUMMY)
	enemy.controller = ai

	player.opponent = enemy
	enemy.opponent = player

	_reset_positions()

func _make_fighter(is_player: bool, fname: String, an: AttackFrameData, ac1: AttackFrameData, ac: AttackFrameData, pd: AttackFrameData, rd: AttackFrameData, hn: ReactionFrameData, hc: ReactionFrameData, hp: ReactionFrameData) -> Fighter:
	var f := Fighter.new()
	f.is_player = is_player
	f.fighter_name = fname
	f.attack_normal_data = an
	f.attack_charge_t1_data = ac1
	f.attack_charge_data = ac
	f.parry_data = pd
	f.roll_data = rd
	f.hit_normal_reaction = hn
	f.hit_charge_reaction = hc
	f.hit_parried_reaction = hp
	return f

func _wire_hud_and_debug() -> void:
	hud.player = player
	hud.enemy = enemy
	hud.ai_controller = ai
	debug_overlay.fighters = [player, enemy]

func _reset_positions() -> void:
	var center := get_viewport_rect().size.x * 0.5
	player.reset(Vector2(center - SPAWN_X_OFFSET, GROUND_Y))
	enemy.reset(Vector2(center + SPAWN_X_OFFSET, GROUND_Y))
	player.facing = 1
	enemy.facing = -1
