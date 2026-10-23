class_name Lighthouse
extends Control

## 灯塔：塔身、灯室、光柱全部 _draw() 画出来。
## 光柱用一条循环 Tween 驱动 sweep（0..1），再由 sin 换算成角度，
## 这样不需要 _process 也不会每帧读状态。

const BEAM_BASE := PI
const SWEEP_RANGE := 0.22
const SWEEP_SECONDS := 7.0

## 0..1 循环，驱动光柱左右扫
var sweep := 0.0:
	set(value):
		sweep = value
		beam_angle = BEAM_BASE + sin(value * TAU) * SWEEP_RANGE
		queue_redraw()

var beam_angle := BEAM_BASE

## 灯光强度。判错调暗，成功调亮。
var energy := 1.0:
	set(value):
		energy = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_loops()
	tween.tween_property(self, "sweep", 1.0, SWEEP_SECONDS).from(0.0)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var horizon := size.y * 0.64
	var base_x := size.x * 0.875
	var lamp := Vector2(base_x, horizon - 152.0)

	_draw_beam(lamp)
	_draw_tower(base_x, horizon)
	_draw_reflection(lamp)
	_draw_lamp(lamp)


func _draw_beam(lamp: Vector2) -> void:
	# 沿光柱方向切成很多小四边形，逐片降低透明度。
	# 用三角形叠层会在每层末端留下一条硬边；切片法没有这个问题。
	# 仍然不用任何贴图。
	var length := size.x * 0.62
	var half_angle := 0.085
	var steps := 14
	var tan_half := tan(half_angle)

	var dir := Vector2(cos(beam_angle), sin(beam_angle))
	var perp := Vector2(-dir.y, dir.x)

	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var d0 := length * t0
		var d1 := length * t1
		var w0 := d0 * tan_half + 3.0
		var w1 := d1 * tan_half + 3.0
		var c0 := lamp + dir * d0
		var c1 := lamp + dir * d1
		var mid_t := (t0 + t1) * 0.5
		var alpha := 0.11 * energy * pow(1.0 - mid_t, 1.7)
		draw_colored_polygon(
			PackedVector2Array([
				c0 - perp * w0,
				c0 + perp * w0,
				c1 + perp * w1,
				c1 - perp * w1,
			]),
			Color(1.0, 0.86, 0.58, alpha)
		)


func _draw_tower(base_x: float, horizon: float) -> void:
	var body := PackedVector2Array([
		Vector2(base_x - 46.0, horizon + 8.0),
		Vector2(base_x - 16.0, horizon - 148.0),
		Vector2(base_x + 16.0, horizon - 148.0),
		Vector2(base_x + 46.0, horizon + 8.0),
	])
	draw_colored_polygon(body, Color(0.022, 0.036, 0.050, 0.96))

	# 边缘高光：让纯黑塔身在雾里有一点点体积感
	draw_line(
		Vector2(base_x - 46.0, horizon + 8.0),
		Vector2(base_x - 16.0, horizon - 148.0),
		Color(0.42, 0.52, 0.50, 0.30),
		1.5
	)

	draw_rect(
		Rect2(base_x - 20.0, horizon - 176.0, 40.0, 30.0),
		Color(0.016, 0.028, 0.040, 0.98)
	)

	var roof := PackedVector2Array([
		Vector2(base_x - 27.0, horizon - 176.0),
		Vector2(base_x, horizon - 200.0),
		Vector2(base_x + 27.0, horizon - 176.0),
	])
	draw_colored_polygon(roof, Color(0.016, 0.028, 0.040, 0.98))


func _draw_lamp(lamp: Vector2) -> void:
	var clamped := clampf(energy, 0.0, 2.4)
	# 只留两层小光晕：大半径的柔光叠在黑塔身上会变成一块灰斑
	draw_circle(lamp, 16.0, Color(1.0, 0.86, 0.58, 0.13 * clamped))
	draw_circle(lamp, 7.0, Color(1.0, 0.92, 0.70, 0.90 * clamped))


## 水面倒影：几层逐渐变宽变淡的多边形叠加，模拟光在水里的扩散
func _draw_reflection(lamp: Vector2) -> void:
	var horizon := size.y * 0.64
	var clamped := clampf(energy, 0.0, 2.4)
	for i in 4:
		var t := float(i) / 4.0
		var w_top := 13.0 - t * 5.0
		var w_bottom := 28.0 + t * 22.0
		var top := horizon + 4.0 + t * 24.0
		var bottom := horizon + 132.0
		var alpha := 0.055 * clamped * (1.0 - t * 0.55)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(lamp.x - w_top, top),
				Vector2(lamp.x + w_top, top),
				Vector2(lamp.x + w_bottom, bottom),
				Vector2(lamp.x - w_bottom, bottom),
			]),
			Color(1.0, 0.86, 0.58, alpha)
		)
