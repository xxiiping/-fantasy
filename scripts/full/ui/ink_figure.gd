class_name InkFigure
extends Control

## 水墨剪影人物。
##
## 不做五官、不做表情差分 —— 情绪只靠**轮廓与姿态**。
## 每个角色只调几个参数（身高、前倾、抬臂、坐姿、提灯），
## 得到水墨人物该有的"几笔"感，而不是细节堆出来的写实剪影。

enum Who { ZHENGHE, QI7, AYUAN }

signal figure_clicked

@export var who: Who = Who.ZHENGHE:
	set(value):
		who = value
		_apply_preset()
		queue_redraw()

@export var body_height := 0.72:
	set(value):
		body_height = value
		queue_redraw()

## 前倾角度（弧度）。丙七是佝偻的
@export var lean := 0.0:
	set(value):
		lean = value
		queue_redraw()

## 抬臂程度 0..1
@export var arm_lift := 0.0:
	set(value):
		arm_lift = value
		queue_redraw()

@export var sitting := false:
	set(value):
		sitting = value
		queue_redraw()

@export var holding_lamp := false:
	set(value):
		holding_lamp = value
		queue_redraw()

@export var ink := Color(0.09, 0.09, 0.11):
	set(value):
		ink = value
		queue_redraw()

## 头身比。小孩的头相对更大
@export var head_scale := 1.0

var _hover := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_preset()
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw()
	)


func _apply_preset() -> void:
	if not is_inside_tree():
		return
	match who:
		Who.ZHENGHE:
			body_height = 0.72
			lean = 0.02
			arm_lift = 0.0
			sitting = false
			holding_lamp = false
			head_scale = 1.0
		Who.QI7:
			body_height = 0.66
			lean = 0.16
			arm_lift = 0.25
			sitting = false
			holding_lamp = true
			head_scale = 1.0
		Who.AYUAN:
			body_height = 0.46
			lean = 0.0
			arm_lift = 0.0
			sitting = false
			holding_lamp = false
			head_scale = 1.35


## 回声动作循环：抬手看星 → 回头看潮 → 拉缆绳 → 回到原位。
##
## 他们要"同时做"，不能错开相位 —— 错开就像人群，同步才像诅咒。
func play_echo_loop(phase := 0.0) -> void:
	var tween := create_tween().set_loops()
	if phase > 0.0:
		tween.tween_interval(phase)
	tween.tween_property(self, "arm_lift", 1.0, 0.55)
	tween.tween_interval(0.35)
	tween.tween_property(self, "lean", 0.24, 0.45)
	tween.tween_interval(0.25)
	tween.tween_property(self, "arm_lift", 0.0, 0.45)
	tween.tween_property(self, "lean", 0.0, 0.40)
	tween.tween_interval(1.30)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			figure_clicked.emit()
			accept_event()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var ground := Vector2(size.x * 0.5, size.y * 0.97)
	var full_h := size.y * body_height
	var head_radius := full_h * 0.075 * head_scale

	# 坐姿：整体压低，腿横着画
	var torso_bottom := 0.0
	if sitting:
		full_h *= 0.62
		torso_bottom = -full_h * 0.10

	var neck := -full_h + head_radius * 2.1
	var waist := -full_h * 0.48
	var lean_px := full_h * lean

	var alpha := 1.0 if not _hover else 0.92

	# 落墨：由外到内画四遍，外圈更大更淡 —— 边缘就有了墨洇开的软边。
	# 只画一遍会变成硬边图标，不像墨。
	var passes := [
		[9.0, 0.07],
		[5.5, 0.13],
		[2.5, 0.26],
		[0.0, 0.90],
	]
	for pass_data in passes:
		var grow: float = pass_data[0]
		var pass_alpha: float = pass_data[1]
		var color := Color(ink.r, ink.g, ink.b, pass_alpha * alpha)
		_paint_torso(ground, neck, waist, torso_bottom, head_radius, lean_px, color, grow)
		_paint_arms(ground, neck, full_h, lean_px, color, holding_lamp and grow <= 0.01, grow)
		if sitting:
			_paint_legs(ground, full_h, head_radius, color, grow)


func _paint_torso(
	origin: Vector2,
	neck: float,
	waist: float,
	hem: float,
	head_radius: float,
	lean_px: float,
	color: Color,
	grow: float = 0.0,
) -> void:
	var head_center := origin + Vector2(lean_px * 1.4, neck - head_radius * 0.95)
	draw_circle(head_center, head_radius + grow, color)

	var shoulder_w := head_radius * 1.15 + grow
	var waist_w := head_radius * 1.30 + grow
	var hem_w := head_radius * 1.62 + grow

	var top := origin + Vector2(lean_px, neck)
	var mid := origin + Vector2(lean_px * 0.55, waist)
	var bottom := origin + Vector2(0.0, hem)

	draw_colored_polygon(
		PackedVector2Array([
			top + Vector2(-shoulder_w, 0.0),
			top + Vector2(shoulder_w, 0.0),
			mid + Vector2(waist_w, 0.0),
			bottom + Vector2(hem_w, 0.0),
			bottom + Vector2(-hem_w, 0.0),
			mid + Vector2(-waist_w, 0.0),
		]),
		color
	)


func _paint_arms(
	origin: Vector2,
	neck: float,
	full_h: float,
	lean_px: float,
	color: Color,
	with_lamp: bool,
	grow: float = 0.0,
) -> void:
	var shoulder := origin + Vector2(lean_px, neck + full_h * 0.04)
	var arm_len := full_h * 0.26
	var thickness := full_h * 0.032 + grow * 1.6

	_stroke(
		PackedVector2Array([
			shoulder + Vector2(-full_h * 0.05, 0.0),
			shoulder + Vector2(-full_h * 0.085, arm_len),
		]),
		thickness,
		color
	)

	var hand := shoulder + Vector2(
		full_h * (0.075 + 0.10 * arm_lift),
		arm_len * (1.0 - 0.85 * arm_lift)
	)
	_stroke(PackedVector2Array([shoulder + Vector2(full_h * 0.05, 0.0), hand]), thickness, color)

	if with_lamp:
		var lamp_pos := hand + Vector2(full_h * 0.05, arm_len * 0.24)
		_stroke(PackedVector2Array([hand, lamp_pos]), thickness * 0.5, color)
		draw_circle(lamp_pos, full_h * 0.055, Color(0.78, 0.44, 0.28, 0.16))
		draw_circle(lamp_pos, full_h * 0.022, Color(0.90, 0.66, 0.42, 0.85))


## 坐姿：一条横向的大腿 + 一条垂下的小腿
func _paint_legs(
	ground: Vector2, full_h: float, head_radius: float, color: Color, grow: float = 0.0
) -> void:
	var hip := ground + Vector2(head_radius * 0.4, -full_h * 0.10)
	var knee := hip + Vector2(full_h * 0.30, 0.0)
	var foot := knee + Vector2(full_h * 0.02, full_h * 0.26)
	_stroke(PackedVector2Array([hip, knee]), head_radius * 0.55 + grow, color)
	_stroke(PackedVector2Array([knee, foot]), head_radius * 0.45 + grow, color)


## 把一条折线画成有粗细的笔画
func _stroke(points: PackedVector2Array, thickness: float, color: Color) -> void:
	if points.size() < 2:
		return

	var polygon := PackedVector2Array()
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []

	for i in points.size():
		var point: Vector2 = points[i]
		var direction: Vector2
		if i == 0:
			direction = points[1] - point
		elif i == points.size() - 1:
			direction = point - points[i - 1]
		else:
			direction = points[i + 1] - points[i - 1]
		if direction.length() < 0.001:
			direction = Vector2.DOWN
		var normal := direction.normalized().orthogonal() * thickness * 0.5
		left.append(point + normal)
		right.append(point - normal)

	for v in left:
		polygon.append(v)
	for i in range(right.size() - 1, -1, -1):
		polygon.append(right[i])
	draw_colored_polygon(polygon, color)
