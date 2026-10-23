class_name DialogueBox
extends Control

## 对话框。宣纸底、墨边、逐字显示。
##
## 点击行为：正在逐字时先把整句显示完；已显示完则推进到下一句。
## 这样玩家永远不会因为手快而漏字。

signal line_finished
signal sequence_finished
signal choice_picked(index: int)

const PAPER := Color(0.925, 0.898, 0.847, 0.92)
const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.35, 0.34, 0.36)
const CHARS_PER_SEC := 26.0

var _panel: PanelContainer
var _margin: MarginContainer
var _vbox: VBoxContainer
var _name_label: Label
var _text_label: RichTextLabel
var _choices: HBoxContainer
var _hint: Label

var _lines: Array[Dictionary] = []
var _index := 0
var _typing := false
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = INK
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 44.0
	style.content_margin_right = 44.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 22.0
	_panel.add_theme_stylebox_override("panel", style)

	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 120.0
	_panel.offset_right = -120.0
	_panel.offset_top = -260.0
	_panel.offset_bottom = -64.0

	_margin = MarginContainer.new()
	_panel.add_child(_margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 14)
	_margin.add_child(_vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", INK_SOFT)
	_vbox.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 24)
	_text_label.add_theme_color_override("default_color", INK)
	_vbox.add_child(_text_label)

	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", 24)
	_choices.alignment = BoxContainer.ALIGNMENT_BEGIN
	_choices.visible = false
	_vbox.add_child(_choices)

	_hint = Label.new()
	_hint.text = "▾"
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", INK_SOFT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_vbox.add_child(_hint)


# ---------------------------------------------------------------- 对外

## lines: [{ "name": "丙七", "text": "……" }, ...]
func play(lines: Array) -> void:
	_lines.clear()
	for line in lines:
		_lines.append(line)
	_index = 0
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_show_current()


func hide_box() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	visible = false


## 在当前句之后接一组选项
func ask(prompt: Array, options: PackedStringArray) -> void:
	play(prompt)
	await sequence_finished
	_show_choices(options)


func _show_choices(options: PackedStringArray) -> void:
	for child in _choices.get_children():
		child.queue_free()
	_choices.visible = true
	_hint.visible = false

	for i in options.size():
		var button := Button.new()
		button.text = "　" + options[i] + "　"
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", Color(0.62, 0.22, 0.18))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		style.border_color = Color(0.10, 0.10, 0.12, 0.35)
		style.set_border_width_all(1)
		style.content_margin_left = 18.0
		style.content_margin_right = 18.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.pressed.connect(_on_choice.bind(i))
		_choices.add_child(button)


## 在当前这段话之后弹出选项（由场景脚本调用）
func show_choices(options: PackedStringArray) -> void:
	_show_choices(options)


# ---------------------------------------------------------------- 内部

func _show_current() -> void:
	if _index >= _lines.size():
		return

	var line: Dictionary = _lines[_index]
	_name_label.text = String(line.get("name", ""))
	_text_label.text = String(line.get("text", ""))

	_text_label.visible_ratio = 0.0
	_typing = true
	_hint.visible = false

	if _tween != null and _tween.is_valid():
		_tween.kill()
	var length := _text_label.get_total_character_count()
	var duration := maxf(0.15, float(length) / CHARS_PER_SEC)
	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typing_done)


func _on_typing_done() -> void:
	_typing = false
	_hint.visible = true
	line_finished.emit()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if _choices.visible:
		return
	_advance()


func _advance() -> void:
	if _typing:
		# 先补完这一句，不漏字
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_text_label.visible_ratio = 1.0
		_typing = false
		_hint.visible = true
		line_finished.emit()
		return

	_index += 1
	if _index >= _lines.size():
		_hint.visible = false
		sequence_finished.emit()
		return
	_show_current()


func _on_choice(index: int) -> void:
	_choices.visible = false
	choice_picked.emit(index)
