class_name DistantLamp
extends Control

## 雾里远处的一盏灯。
##
## 它必须是"灭的"——所以只有轮廓，没有光。
## 玩家看到的应该是一个几乎要与雾融在一起的黑影，只有一道细边把它勾出来。
## 这种"差点看不见"才是这一场要的效果。

const INK := Color(0.10, 0.10, 0.12)

@export var reveal := 0.0:
	set(value):
		reveal = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func reveal_over(seconds := 2.0) -> void:
	var tween := create_tween()
	tween.tween_property(self, "reveal", 1.0, seconds)


func _draw() -> void:
	if reveal <= 0.001:
		return

	var base := Vector2(size.x * 0.5, size.y * 0.90)
	var top_y := size.y * 0.16
	var half_base := size.x * 0.20
	var half_top := size.x * 0.075
	var neck_y := top_y + size.y * 0.11

	# 塔身：极淡，几乎要被雾吃掉
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(base.x - half_base, base.y),
			Vector2(base.x - half_top, neck_y),
			Vector2(base.x + half_top, neck_y),
			Vector2(base.x + half_base, base.y),
		]),
		Color(INK.r, INK.g, INK.b, 0.13 * reveal)
	)

	# 灯室：稍实一点，是整座塔唯一"像人造物"的地方
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(base.x - half_top * 1.35, neck_y),
			Vector2(base.x + half_top * 1.35, neck_y),
			Vector2(base.x + half_top * 1.15, top_y),
			Vector2(base.x - half_top * 1.15, top_y),
		]),
		Color(INK.r, INK.g, INK.b, 0.24 * reveal)
	)
