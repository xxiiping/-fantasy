class_name InkSpot
extends Control

## 画面上一个可点的墨点：探索点、卡槽都用它。
##
## 三种状态：未用（虚环）、已用（实心 + 划掉）、锁定（更淡）。

signal spot_pressed

@export var label_text := "":
	set(value):
		label_text = value
		queue_redraw()

@export var used := false:
	set(value):
		used = value
		queue_redraw()

@export var locked := false:
	set(value):
		locked = value
		queue_redraw()

@export var radius := 34.0:
	set(value):
		radius = value
		queue_redraw()

const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.30, 0.29, 0.31)

var _hover := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw()
	)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if locked or used:
		return
	spot_pressed.emit()
	accept_event()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var alpha := 0.85
	if used:
		alpha = 0.30
	elif locked:
		alpha = 0.22

	if _hover and not used and not locked:
		draw_circle(center, radius * 1.30, Color(INK.r, INK.g, INK.b, 0.06))

	if used:
		draw_circle(center, radius * 0.55, Color(INK.r, INK.g, INK.b, alpha))
	else:
		InkBrush.ring(self, center, radius, Color(INK.r, INK.g, INK.b, alpha), 1.8)

	var font := get_theme_default_font()
	if font != null and not label_text.is_empty():
		var font_size := 19
		var width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var color := INK_SOFT if not used else Color(INK_SOFT.r, INK_SOFT.g, INK_SOFT.b, 0.45)
		draw_string(
			font,
			Vector2(center.x - width * 0.5, center.y + radius + 28.0),
			label_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			color
		)
