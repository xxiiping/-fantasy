class_name AttemptLamp
extends Control

## 一盏"剩余验证次数"灯。亮 = 还剩一次机会，灭 = 用掉了。

const LAMP_SIZE := 22.0
const DOT_RADIUS := 6.5

var lit := true


func _init() -> void:
	custom_minimum_size = Vector2(LAMP_SIZE, LAMP_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_lit(value: bool) -> void:
	if lit == value:
		return
	lit = value
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	if lit:
		draw_circle(center, DOT_RADIUS, Color("f2c879"))
		draw_circle(center, DOT_RADIUS * 1.7, Color(0.949, 0.784, 0.475, 0.16))
	else:
		draw_arc(center, DOT_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.20), 1.3, true)
