class_name RuneAltar
extends Control

## 符文机关（水墨版）。
##
## 规则完全复用旧的 GameState —— 它是不含节点的纯逻辑，12 条单测覆盖过。
## 这里只负责画：石盘、三枚符文、输入槽、次数。
## **本文件里没有任何一行判定逻辑。**

signal resolved(success: bool)
signal mistake(attempts_left: int)

const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.28, 0.27, 0.29)

const RUNE_BOX := 176.0
const RUNE_SPACING := 250.0
const SLOT_RADIUS := 26.0

var config: PuzzleConfig
var state: GameState
var hint_enabled := false

var _runes: Array[InkRune] = []
var _locked := false
var _feedback := ""
var _feedback_ink := INK_SOFT
var _hint_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func configure(p_config: PuzzleConfig, p_state: GameState, p_hint: bool) -> void:
	config = p_config
	state = p_state
	hint_enabled = p_hint
	if is_node_ready():
		_build()


# ---------------------------------------------------------------- 搭建

func _build() -> void:
	for child in get_children():
		child.queue_free()
	_runes.clear()

	if config == null:
		return

	for rune_def in config.runes:
		var rune := InkRune.new()
		rune.setup(rune_def)
		rune.rune_pressed.connect(_on_rune_pressed)
		add_child(rune)
		_runes.append(rune)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 22)
	_hint_label.add_theme_color_override("font_color", INK_SOFT)
	_hint_label.visible = hint_enabled and not config.hint_text.is_empty()
	_hint_label.text = config.hint_text if _hint_label.visible else ""
	add_child(_hint_label)

	_feedback = ""
	_feedback_ink = INK_SOFT
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	var visible_count := _runes.size()
	if visible_count == 0:
		return

	var spacing := minf(RUNE_SPACING, size.x / float(visible_count + 1))
	var row_width := spacing * float(visible_count - 1)
	var start_x := size.x * 0.5 - row_width * 0.5
	var center_y := size.y * 0.42

	for i in visible_count:
		var rune := _runes[i]
		rune.size = Vector2(RUNE_BOX, RUNE_BOX)
		rune.position = Vector2(
			start_x + spacing * float(i) - RUNE_BOX * 0.5,
			center_y - RUNE_BOX * 0.5
		)

	if _hint_label != null:
		_hint_label.size = Vector2(size.x * 0.7, 44.0)
		_hint_label.position = Vector2(size.x * 0.15, size.y * 0.075)

	queue_redraw()


# ---------------------------------------------------------------- 交互

func _on_rune_pressed(rune_id: StringName) -> void:
	if _locked or state == null or not state.can_accept_input():
		return

	var result := state.push_rune(rune_id)
	_refresh()

	if not result.judged:
		return

	if result.success:
		_feedback = config.feedback_correct
		_feedback_ink = Color(0.62, 0.22, 0.18)
		queue_redraw()
		Sfx.correct()
		_finish(true)
	elif result.settled:
		_feedback = config.feedback_failed if not config.feedback_failed.is_empty() else config.feedback_wrong
		_feedback_ink = Color(0.62, 0.22, 0.18)
		queue_redraw()
		Sfx.wrong()
		mistake.emit(state.attempts_left)
		_finish(false)
	else:
		_feedback = config.feedback_wrong
		_feedback_ink = Color(0.62, 0.22, 0.18)
		queue_redraw()
		Sfx.wrong()
		mistake.emit(state.attempts_left)


func _finish(success: bool) -> void:
	if _locked:
		return
	_locked = true
	for rune in _runes:
		rune.enabled = false

	await get_tree().create_timer(1.1).timeout
	if is_inside_tree():
		resolved.emit(success)


func _refresh() -> void:
	queue_redraw()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	if config == null or state == null:
		return

	var center := Vector2(size.x * 0.5, size.y * 0.42)
	var disc_radius := minf(size.x * 0.34, size.y * 0.40)

	# 石盘：三圈半径略有差异的墨环，粗细不一 —— 才像手画的，不像矢量圆
	draw_circle(center, disc_radius, Color(INK.r, INK.g, INK.b, 0.030))
	InkBrush.ring(self, center, disc_radius, Color(INK.r, INK.g, INK.b, 0.34), 2.6)
	InkBrush.ring(self, center, disc_radius - 8.0, Color(INK.r, INK.g, INK.b, 0.16), 1.2)
	InkBrush.ring(self, center, disc_radius + 5.0, Color(INK.r, INK.g, INK.b, 0.09), 3.4)

	_draw_slots()
	_draw_attempts()
	_draw_feedback()


func _draw_slots() -> void:
	var count := state.required_count()
	if count == 0:
		return

	var spacing := minf(RUNE_SPACING, size.x / float(count + 1))
	var row_width := spacing * float(count - 1)
	var start_x := size.x * 0.5 - row_width * 0.5
	var y := size.y * 0.42 + RUNE_BOX * 0.62

	var font := get_theme_default_font()

	for i in count:
		var slot_center := Vector2(start_x + spacing * float(i), y)

		if i < state.input.size():
			# 已填：实心墨点 + 名字
			var rune_def := config.rune_by_id(state.input[i])
			draw_circle(slot_center, SLOT_RADIUS * 0.62, Color(INK.r, INK.g, INK.b, 0.88))
			if rune_def != null and font != null:
				var text := rune_def.display_name
				var font_size := 18
				var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				draw_string(
					font,
					slot_center + Vector2(-width * 0.5, SLOT_RADIUS + 26.0),
					text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_size,
					INK_SOFT
				)
		else:
			# 空：虚环
			InkBrush.ring(self, slot_center, SLOT_RADIUS * 0.62, Color(INK.r, INK.g, INK.b, 0.30), 1.2)


func _draw_attempts() -> void:
	if state.unlimited_attempts:
		return
	var x := size.x - 40.0
	var y := 48.0
	for i in state.max_attempts:
		var lit := i < state.attempts_left
		var center := Vector2(x - float(i) * 22.0, y)
		if lit:
			draw_circle(center, 5.5, Color(INK.r, INK.g, INK.b, 0.85))
		else:
			InkBrush.ring(self, center, 5.5, Color(INK.r, INK.g, INK.b, 0.28), 1.0)


func _draw_feedback() -> void:
	if _feedback.is_empty():
		return
	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := 22
	var width := font.get_string_size(_feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		Vector2(size.x * 0.5 - width * 0.5, size.y * 0.90),
		_feedback,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		_feedback_ink
	)
