class_name HUD
extends Node2D

var player: Fighter
var enemy: Fighter
var ai_controller: AIController

const BAR_WIDTH := 360.0
const BAR_HEIGHT := 18.0
const BAR_MARGIN := 24.0
const BAR_BG := Color(0.18, 0.18, 0.22, 0.9)
const BAR_BORDER := Color(0.6, 0.6, 0.7, 0.9)
const HP_PLAYER := Color(0.4, 0.85, 0.4)
const HP_ENEMY := Color(0.85, 0.45, 0.45)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var viewport := get_viewport_rect().size
	# Player HP (left)
	_draw_hp_bar(Vector2(BAR_MARGIN, BAR_MARGIN), player, HP_PLAYER, false)
	# Enemy HP (right, mirrored)
	_draw_hp_bar(Vector2(viewport.x - BAR_MARGIN - BAR_WIDTH, BAR_MARGIN), enemy, HP_ENEMY, true)
	# AI mode label (center top)
	var font := ThemeDB.fallback_font
	var size := 14
	var label := "AI: %s   [TAB to toggle]" % (ai_controller.mode_label() if ai_controller else "?")
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
	draw_string(font, Vector2((viewport.x - width) * 0.5, BAR_MARGIN + 14), label, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0.85, 0.85, 1, 0.9))

func _draw_hp_bar(pos: Vector2, fighter: Fighter, fill_color: Color, mirrored: bool) -> void:
	if fighter == null:
		return
	draw_rect(Rect2(pos, Vector2(BAR_WIDTH, BAR_HEIGHT)), BAR_BG)
	var hp_pct: float = float(fighter.hp) / float(Fighter.MAX_HP)
	var fill_width: float = BAR_WIDTH * hp_pct
	var fill_rect: Rect2
	if mirrored:
		fill_rect = Rect2(pos + Vector2(BAR_WIDTH - fill_width, 0), Vector2(fill_width, BAR_HEIGHT))
	else:
		fill_rect = Rect2(pos, Vector2(fill_width, BAR_HEIGHT))
	draw_rect(fill_rect, fill_color)
	draw_rect(Rect2(pos, Vector2(BAR_WIDTH, BAR_HEIGHT)), BAR_BORDER, false, 1.5)

	var font := ThemeDB.fallback_font
	var size := 13
	var name_text: String = "%s   %d / %d" % [fighter.fighter_name, fighter.hp, Fighter.MAX_HP]
	var align: int = HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
	draw_string(font, pos + Vector2(0, BAR_HEIGHT + 16), name_text, align, BAR_WIDTH, size, Color(1, 1, 1, 0.85))
