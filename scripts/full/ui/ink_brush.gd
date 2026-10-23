class_name InkBrush
extends RefCounted

## 把折线画成"有粗细的笔画"，供剪影与符文共用。
##
## 水墨的关键不是形状，是**边缘的洇**：
## 所以同一笔要由粗到细画几遍，外圈更大更淡，边缘才有湿墨化开的软边。


## 画一笔。
##
## 用 draw_polyline 而不是 draw_colored_polygon：
## 螺旋、波纹这种急弯处，偏移出来的多边形会自交，三角化直接失败；
## polyline 按线段画，永远不会出这个问题，视觉上也一样能做多遍晕染。
static func stroke(
	canvas: CanvasItem,
	points: PackedVector2Array,
	thickness: float,
	color: Color,
	passes: int = 3,
	bleed: float = 2.2,
) -> void:
	if points.size() < 2 or thickness <= 0.0:
		return

	for index in passes:
		var t := float(index) / float(maxi(1, passes - 1))
		var grow := (1.0 - t) * bleed
		var alpha := color.a * (0.16 + 0.84 * t)
		var layer := Color(color.r, color.g, color.b, alpha)
		canvas.draw_polyline(points, layer, thickness + grow, true)


## 只画折线的前 ratio 比例，用于"笔画生长"
static func slice(points: PackedVector2Array, ratio: float) -> PackedVector2Array:
	if ratio <= 0.0:
		return PackedVector2Array()
	if ratio >= 1.0:
		return points
	var take := maxi(2, int(round(float(points.size()) * ratio)))
	var out := PackedVector2Array()
	for i in mini(take, points.size()):
		out.append(points[i])
	return out


## 画一个圆环（石盘、灯圈）
static func ring(canvas: CanvasItem, center: Vector2, radius: float, color: Color, width: float = 2.0) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, 72, color, width, true)
	canvas.draw_arc(center, radius + 1.5, 0.0, TAU, 72, Color(color.r, color.g, color.b, color.a * 0.25), width * 2.0, true)
