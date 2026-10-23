class_name RuneSlot
extends Control

## 一个输入槽。空着是暗环，填上就显示符文名与对应颜色。
## 纯 _draw()，无子节点，无贴图。

const SLOT_SIZE := 78.0
const RADIUS := 25.0

var filled := false
var rune_name := ""
var tint := Color(0.85, 0.9, 0.95)


func _init() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_rune(display_name: String, color: Color) -> void:
	filled = true
	rune_name = display_name
	tint = color
	queue_redraw()


func clear() -> void:
	filled = false
	rune_name = ""
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5

	if filled:
		draw_circle(center, RADIUS, Color(tint.r, tint.g, tint.b, 0.16))
		draw_arc(center, RADIUS, 0.0, TAU, 48, tint, 2.0, true)
	else:
		draw_arc(center, RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.18), 1.4, true)

	if filled and not rune_name.is_empty():
		var font := get_theme_default_font()
		if font == null:
			return
		var font_size := 16
		var width := font.get_string_size(rune_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(
			font,
			center + Vector2(-width * 0.5, float(font_size) * 0.36),
			rune_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			tint,
		)
