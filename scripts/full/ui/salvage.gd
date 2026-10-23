class_name Salvage
extends Control

## 2-3 打捞。
##
## 三次下潜，五个位置。这是全游戏第一个"有代价的选择"：
## 捞错了不是失败，是**少了线索**，后面的谜题会变难但仍然可解。
##
## 米袋是唯一一个"倒扣"的坑：它不但什么都没有，还会多消耗一次。

signal finished(found: Dictionary)

const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.30, 0.29, 0.31)
const DIVE_LIMIT := 3

## 五个位置：名字、相对坐标
const SPOTS := [
	{"name": "书匣", "pos": Vector2(0.30, 0.27)},
	{"name": "货箱", "pos": Vector2(0.50, 0.35)},
	{"name": "小箱", "pos": Vector2(0.70, 0.25)},
	{"name": "米袋", "pos": Vector2(0.54, 0.45)},
	{"name": "破口", "pos": Vector2(0.18, 0.43)},
]

var _dialogue: DialogueBox
var _spots: Array[InkSpot] = []
var _dives := DIVE_LIMIT
var _found := {}
var _busy := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func run(dialogue: DialogueBox) -> void:
	_dialogue = dialogue
	_build()
	# 等一帧让控件拿到真实尺寸，再排一次版 —— 否则五个点会挤在左上角
	await get_tree().process_frame
	_layout()

	await _say([
		{"name": "郑和", "text": "三次。"},
		{"name": "郑和", "text": "水太冷，人下去三次就没力气了。"},
	])

	_set_enabled(true)
	await _await_done()
	_set_enabled(false)

	await _say([
		{"name": "", "text": "人上来了。\n水面上什么都没留下。"},
	])

	finished.emit(_found)


# ---------------------------------------------------------------- 搭建

func _build() -> void:
	for child in get_children():
		child.queue_free()
	_spots.clear()

	for entry in SPOTS:
		var spot := InkSpot.new()
		spot.label_text = String(entry["name"])
		spot.radius = 24.0
		spot.locked = true
		spot.spot_pressed.connect(_on_spot_pressed.bind(spot, String(entry["name"])))
		add_child(spot)
		_spots.append(spot)

	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	for i in _spots.size():
		var entry: Dictionary = SPOTS[i]
		var pos: Vector2 = entry["pos"]
		var spot := _spots[i]
		spot.size = Vector2(110.0, 110.0)
		spot.position = Vector2(size.x * pos.x - 55.0, size.y * pos.y - 45.0)
	queue_redraw()


func _set_enabled(value: bool) -> void:
	for spot in _spots:
		spot.locked = not value


# ---------------------------------------------------------------- 交互

func _on_spot_pressed(spot: InkSpot, spot_name: String) -> void:
	if _busy or _dives <= 0:
		return
	_busy = true
	spot.used = true
	_dives -= 1

	match spot_name:
		"书匣":
			_found["船志"] = true
			await _say([
				{"name": "", "text": "船长室的书匣。\n里面是一叠泡开的纸。"},
				{"name": "", "text": "字迹化开了一半，但还读得出几行。"},
			])
		"货箱":
			_found["灯油"] = int(_found.get("灯油", 0)) + 2
			await _say([{"name": "", "text": "两罐灯油，封着，没进水。"}])
		"小箱":
			_found["镜片"] = true
			await _say([
				{"name": "", "text": "一个上锁的小箱。锁早烂了。"},
				{"name": "", "text": "里面是一枚镜片。\n不是这艘船的尺寸。"},
			])
		"米袋":
			# 唯一一个倒扣的坑
			_dives -= 1
			await _say([
				{"name": "", "text": "米袋泡烂了，一抓就散。"},
				{"name": "", "text": "白费了一次力气。"},
			])
		"破口":
			await _say([
				{"name": "", "text": "破口边缘的水在动。"},
				{"name": "", "text": "人还没下去就被冲回来了。"},
			])

	queue_redraw()
	_busy = false


func _await_done() -> void:
	while _dives > 0:
		await get_tree().create_timer(0.1).timeout


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	var left := size.x * 0.10
	var right := size.x * 0.90
	var top := size.y * 0.12
	var bottom := size.y * 0.54
	var corner := size.x * 0.10

	# 船体剖面：上沿直、下沿收成圆弧
	var hull := PackedVector2Array()
	hull.append(Vector2(left, top))
	hull.append(Vector2(right, top))
	hull.append(Vector2(right, bottom - corner))
	# 底线圆弧：圆心居中、半径取一半宽减圆角。
	# 之前写成从右边起算的偏移，弧线会冲出边界，多边形自交、三角化直接失败。
	var arc_center := (left + right) * 0.5
	var arc_half := (right - left) * 0.5 - corner
	for i in 13:
		var t := float(i) / 12.0
		var angle := t * PI
		hull.append(Vector2(
			arc_center + cos(angle) * arc_half,
			bottom - corner + sin(angle) * corner
		))
	hull.append(Vector2(left, bottom - corner))

	draw_colored_polygon(hull, Color(INK.r, INK.g, INK.b, 0.06))
	# 舷线
	for i in hull.size() - 1:
		var a := hull[i]
		var b := hull[i + 1]
		draw_line(a, b, Color(INK.r, INK.g, INK.b, 0.55), 2.0, true)

	# 水线
	var water_y := size.y * 0.47
	draw_line(
		Vector2(left + 8.0, water_y),
		Vector2(right - 8.0, water_y),
		Color(INK.r, INK.g, INK.b, 0.22),
		1.4
	)

	# 剩下的下潜次数
	var font := get_theme_default_font()
	if font != null:
		var text := "下潜  %d / %d" % [_dives, DIVE_LIMIT]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(
			font,
			Vector2(size.x - width - 40.0, size.y * 0.14),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			INK_SOFT
		)
		for i in DIVE_LIMIT:
			var center := Vector2(size.x - 46.0 - float(i) * 24.0, size.y * 0.14 + 30.0)
			if i < _dives:
				draw_circle(center, 6.0, Color(INK.r, INK.g, INK.b, 0.85))
			else:
				InkBrush.ring(self, center, 6.0, Color(INK.r, INK.g, INK.b, 0.25), 1.0)


# ---------------------------------------------------------------- 工具

func _say(lines: Array) -> void:
	_dialogue.play(lines)
	await _dialogue.sequence_finished
