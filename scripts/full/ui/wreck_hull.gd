class_name WreckHull
extends Control

## 雾中横着的一艘商船。
##
## 它必须是"没有腐烂"的 —— 所以轮廓要完整、干净，
## 只是断了一根桅杆。那种"还好好的却已经死了"的违和感就在这里。

const INK := Color(0.10, 0.10, 0.12)

## 0..1，用于淡入
@export var reveal := 1.0:
	set(value):
		reveal = value
		queue_redraw()

@export var broken_mast := true:
	set(value):
		broken_mast = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if reveal <= 0.001 or size.x < 10.0:
		return

	var deck_y := size.y * 0.56
	var left := size.x * 0.12
	var right := size.x * 0.92
	var alpha := reveal

	# 船体：上沿平、下沿收
	var hull := PackedVector2Array([
		Vector2(left, deck_y),
		Vector2(right, deck_y - size.y * 0.02),
		Vector2(right - size.x * 0.10, size.y * 0.90),
		Vector2(left + size.x * 0.13, size.y * 0.88),
	])
	draw_colored_polygon(hull, Color(INK.r, INK.g, INK.b, 0.30 * alpha))

	# 舷线：一笔更实的墨，把甲板那条边压出来
	draw_line(
		Vector2(left, deck_y),
		Vector2(right, deck_y - size.y * 0.02),
		Color(INK.r, INK.g, INK.b, 0.58 * alpha),
		2.2
	)

	# 主桅（完整）
	InkBrush.stroke(
		self,
		PackedVector2Array([
			Vector2(size.x * 0.46, deck_y),
			Vector2(size.x * 0.455, size.y * 0.10),
		]),
		5.0,
		Color(INK.r, INK.g, INK.b, 0.78 * alpha),
		2,
		1.5
	)

	# 断桅：只到一半就折了
	if broken_mast:
		var break_point := Vector2(size.x * 0.70, size.y * 0.36)
		InkBrush.stroke(
			self,
			PackedVector2Array([Vector2(size.x * 0.72, deck_y), break_point]),
			4.5,
			Color(INK.r, INK.g, INK.b, 0.72 * alpha),
			2,
			1.5
		)
		# 断口
		draw_line(
			break_point + Vector2(-7.0, -3.0),
			break_point + Vector2(6.0, 4.0),
			Color(INK.r, INK.g, INK.b, 0.62 * alpha),
			2.0
		)

	# 水线：船底一圈很淡的墨，表示它浮着但没在动
	draw_rect(
		Rect2(Vector2(left + size.x * 0.05, size.y * 0.90), Vector2(size.x * 0.72, 2.0)),
		Color(INK.r, INK.g, INK.b, 0.14 * alpha)
	)
