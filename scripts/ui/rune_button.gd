class_name RuneButton
extends Button

## 一枚符文按钮。字形用 _draw() 程序化画出来，不用任何贴图。
## 点击时 draw_progress 从 0 补间到 1，字形像被"写"出来。

signal rune_pressed(rune_id: StringName)

var definition: RuneDefinition

## 0..1，控制字形画到第几笔。默认 1 —— 符文一出现就是完整的，
## 只有被点击时才从 0 重新"写"一遍。
var draw_progress := 1.0:
	set(value):
		draw_progress = value
		queue_redraw()

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_apply_definition()


func setup(def: RuneDefinition) -> void:
	definition = def
	if is_node_ready():
		_apply_definition()


func _apply_definition() -> void:
	if definition == null:
		return
	name_label.text = definition.display_name
	tooltip_text = definition.display_name
	queue_redraw()


func _on_pressed() -> void:
	if definition == null:
		return
	Sfx.click()
	play_draw()
	rune_pressed.emit(definition.id)


func _on_hover(is_hover: bool) -> void:
	var target := 1.04 if is_hover else 1.0
	create_tween().tween_property(self, "scale", Vector2(target, target), 0.12)


func play_draw() -> void:
	draw_progress = 0.0
	var tween := create_tween()
	tween.tween_property(self, "draw_progress", 1.0, 0.26)


func _draw() -> void:
	if definition == null:
		return

	var center := Vector2(size.x * 0.5, size.y * 0.40)
	var radius := minf(size.x, size.y) * 0.30
	var lines := _glyph_polylines(center, radius)
	if lines.is_empty():
		return

	var color := definition.tint
	color.a = lerpf(0.35, 1.0, draw_progress)

	# 可点击区域的可见底座：暗底 + 细环，否则 flat 按钮看起来不像能点
	var plate := Color(color.r, color.g, color.b, 0.05 if not is_hovered() else 0.10)
	draw_circle(center, radius * 1.28, plate)
	draw_arc(center, radius * 1.28, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.16), 1.0, true)

	# 悬停时补一层柔光
	if is_hovered():
		draw_circle(center, radius * 1.15, Color(color.r, color.g, color.b, 0.07))

	var count := lines.size()
	for i in count:
		var seg_t := clampf(draw_progress * float(count) - float(i), 0.0, 1.0)
		var points := _slice(lines[i], seg_t)
		if points.size() >= 2:
			draw_polyline(points, color, 2.0, true)


## 只取折线的前 t 比例，用来做"笔画生长"
func _slice(points: PackedVector2Array, t: float) -> PackedVector2Array:
	if t <= 0.0:
		return PackedVector2Array()
	if t >= 1.0:
		return points
	var take := maxi(2, int(round(float(points.size()) * t)))
	var out := PackedVector2Array()
	for i in take:
		out.append(points[i])
	return out


## 三种字形，全部由点列构成
func _glyph_polylines(center: Vector2, radius: float) -> Array:
	match definition.glyph:
		RuneDefinition.Glyph.STAR:
			return _polylines_star(center, radius)
		RuneDefinition.Glyph.TIDE:
			return _polylines_tide(center, radius)
		RuneDefinition.Glyph.WIND:
			return _polylines_wind(center, radius)
	return []


## 星象：八道放射线 + outer 菱形
func _polylines_star(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for i in 8:
		var angle := TAU * float(i) / 8.0 - PI * 0.5
		var dir := Vector2(cos(angle), sin(angle))
		var length := radius if i % 2 == 0 else radius * 0.62
		lines.append(PackedVector2Array([center + dir * radius * 0.30, center + dir * length]))

	var diamond := PackedVector2Array()
	for i in 5:
		var angle := TAU * float(i) / 4.0 - PI * 0.5
		diamond.append(center + Vector2(cos(angle), sin(angle)) * radius * 0.72)
	lines.append(diamond)
	return lines


## 海潮：三道正弦波纹
func _polylines_tide(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for row in 3:
		var points := PackedVector2Array()
		var y := center.y + (float(row) - 1.0) * radius * 0.42
		var phase := float(row) * 0.55
		for i in 17:
			var t := float(i) / 16.0
			var x := center.x - radius * 0.82 + t * radius * 1.64
			points.append(Vector2(x, y + sin(t * TAU + phase) * radius * 0.15))
		lines.append(points)
	return lines


## 季风：两道螺旋气流
func _polylines_wind(center: Vector2, radius: float) -> Array:
	var lines: Array = []
	for k in 2:
		var points := PackedVector2Array()
		var offset := float(k) * PI
		for i in 26:
			var t := float(i) / 25.0
			var angle := t * TAU * 1.35 + offset
			var r := radius * (0.16 + t * 0.84)
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
		lines.append(points)
	return lines
