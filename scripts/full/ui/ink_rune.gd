class_name InkRune
extends Control

## 水墨符文。三枚字形全部由笔画生成，不用贴图。
##
## 点击时 progress 从 0 补间到 1，笔画按顺序"写"出来。
## 与旧版（RuneButton）的区别：这里走 InkBrush 的多遍落墨，边缘是软的。

signal rune_pressed(rune_id: StringName)

const INK := Color(0.10, 0.10, 0.12)

@export var definition: RuneDefinition:
	set(value):
		definition = value
		queue_redraw()

## 0..1，控制画到第几笔
var progress := 1.0:
	set(value):
		progress = value
		queue_redraw()

@export var enabled := true:
	set(value):
		enabled = value
		queue_redraw()

## 不可用时（例如无星之夜的星象）整体压淡
@export var dimmed := false:
	set(value):
		dimmed = value
		queue_redraw()

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


func setup(def: RuneDefinition) -> void:
	definition = def


func play_draw() -> void:
	progress = 0.0
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, 0.30)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not enabled or dimmed:
		return
	if definition == null:
		return
	play_draw()
	rune_pressed.emit(definition.id)
	accept_event()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	if definition == null or size.x < 4.0:
		return

	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.32

	var base_alpha := 1.0
	if dimmed:
		base_alpha = 0.22
	elif not enabled:
		base_alpha = 0.45
	if _hover and not dimmed:
		base_alpha = 1.0

	var ink := Color(INK.r, INK.g, INK.b, base_alpha)

	# 悬停时的底盘（很淡的一圈墨，表示可点）
	if _hover and not dimmed and enabled:
		draw_circle(center, radius * 1.42, Color(INK.r, INK.g, INK.b, 0.05))

	var strokes := _build_strokes(center, radius)
	var total := maxi(1, strokes.size())

	for i in strokes.size():
		var reveal := clampf(progress * float(total) - float(i), 0.0, 1.0)
		var points := InkBrush.slice(strokes[i], reveal)
		if points.size() >= 2:
			InkBrush.stroke(self, points, radius * 0.085, ink, 3, radius * 0.075)


## 三种字形的笔画表
func _build_strokes(center: Vector2, radius: float) -> Array:
	match definition.glyph:
		RuneDefinition.Glyph.STAR:
			return _strokes_star(center, radius)
		RuneDefinition.Glyph.TIDE:
			return _strokes_tide(center, radius)
		RuneDefinition.Glyph.WIND:
			return _strokes_wind(center, radius)
	return []


## 星象：四长四短的放射 + 一圈方框（像罗盘）
func _strokes_star(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for i in 8:
		var angle := TAU * float(i) / 8.0 - PI * 0.5
		var dir := Vector2(cos(angle), sin(angle))
		var length := radius if i % 2 == 0 else radius * 0.58
		lines.append(PackedVector2Array([
			center + dir * radius * 0.22,
			center + dir * length,
		]))

	var diamond := PackedVector2Array()
	for i in 5:
		var angle := TAU * float(i) / 4.0 - PI * 0.5
		diamond.append(center + Vector2(cos(angle), sin(angle)) * radius * 0.70)
	lines.append(diamond)

	return lines


## 海潮：三道锋利的波纹，带钩
func _strokes_tide(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for row in 3:
		var points := PackedVector2Array()
		var y := center.y + (float(row) - 1.0) * radius * 0.46
		var phase := float(row) * 0.7
		for i in 19:
			var t := float(i) / 18.0
			var x := center.x - radius * 0.86 + t * radius * 1.72
			points.append(Vector2(x, y + sin(t * TAU + phase) * radius * 0.17))
		lines.append(points)
	return lines


## 季风：两道盘旋的气流
func _strokes_wind(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for k in 2:
		var points := PackedVector2Array()
		var offset := float(k) * PI
		for i in 28:
			var t := float(i) / 27.0
			var angle := t * TAU * 1.25 + offset
			var r := radius * (0.14 + t * 0.86)
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
		lines.append(points)
	return lines
