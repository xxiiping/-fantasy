class_name LampRepair
extends Control

## 1-4 修缮。
##
## 一个自足的小场面：上面三个探索点，下面三个卡槽，中间是那盏空灯。
## 它自己跑完整个流程（探 → 找到灯芯 → 装上去 → 灯亮但昏），
## 只对外抛一个 finished。
##
## 关键设计：**镜片拿不到**。这不是难度，是叙事 ——
## 玩家会意识到"能做的只有这么多"，而这句话由丙七在最后说出来。

signal finished

const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.30, 0.29, 0.31)
const COLOR_WARM := Color(0.78, 0.46, 0.26)

const SPOT_ROW_Y := 0.17
const SOCKET_ROW_Y := 0.47
const LAMP_Y := 0.34

var _dialogue: DialogueBox
var _bag := {"火种": 1}
var _placed := {}
var _spots: Array[InkSpot] = []
var _sockets: Array[InkSpot] = []
var _busy := false
var _lit := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 入口：传进对话框，跑完整段
func run(dialogue: DialogueBox) -> void:
	_dialogue = dialogue
	_build()
	await get_tree().process_frame
	await _say([
		{"name": "丙七", "text": "灯是亮的。\n是灯的东西不在了。"},
	])
	_spots_enabled(true)
	await _await_wick()
	_spots_enabled(false)
	await _say([{"name": "", "text": "灯芯放回座上。"}])
	_sockets_enabled(true)
	await _await_lit()
	_sockets_enabled(false)
	await _say([
		{"name": "", "text": "灯亮起来了。\n可是光是昏的，照不出三尺。"},
		{"name": "丙七", "text": "镜片在别的塔上。"},
		{"name": "丙七", "text": "五座塔，一副镜片。\n老朽这儿，是最后一站。"},
	])
	finished.emit()


# ---------------------------------------------------------------- 搭建

func _build() -> void:
	for child in get_children():
		child.queue_free()
	_spots.clear()
	_sockets.clear()

	var spot_names := ["木箱", "旧柜", "床铺"]
	for i in spot_names.size():
		var spot := InkSpot.new()
		spot.label_text = spot_names[i]
		spot.radius = 30.0
		spot.spot_pressed.connect(_on_spot_pressed.bind(spot))
		add_child(spot)
		_spots.append(spot)

	var socket_names := ["火种", "灯芯", "镜片"]
	for i in socket_names.size():
		var socket := InkSpot.new()
		socket.label_text = socket_names[i]
		socket.radius = 24.0
		socket.spot_pressed.connect(_on_socket_pressed.bind(socket))
		add_child(socket)
		_sockets.append(socket)

	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	var count := 3
	var spacing := size.x / float(count + 1)

	for i in _spots.size():
		var spot := _spots[i]
		spot.size = Vector2(120.0, 130.0)
		spot.position = Vector2(spacing * float(i + 1) - 60.0, size.y * SPOT_ROW_Y - 45.0)

	for i in _sockets.size():
		var socket := _sockets[i]
		socket.size = Vector2(110.0, 120.0)
		socket.position = Vector2(spacing * float(i + 1) - 55.0, size.y * SOCKET_ROW_Y - 20.0)

	queue_redraw()


func _spots_enabled(value: bool) -> void:
	for spot in _spots:
		spot.locked = not value


func _sockets_enabled(value: bool) -> void:
	for socket in _sockets:
		socket.locked = not value


# ---------------------------------------------------------------- 交互

func _on_spot_pressed(spot: InkSpot) -> void:
	if _busy:
		return
	_busy = true

	match spot.label_text:
		"木箱":
			spot.used = true
			if not _bag.has("灯芯"):
				_bag["灯芯"] = 1
				await _say([{"name": "", "text": "箱子里有一截灯芯，\n还带着旧油的味道。"}])
			else:
				await _say([{"name": "", "text": "已经拿过了。"}])
		"旧柜":
			spot.used = true
			await _say([
				{"name": "", "text": "柜子是空的。"},
				{"name": "", "text": "里面叠着一件小衣裳，洗得发白。\n没有说明是谁的。"},
			])
		"床铺":
			await _say([
				{"name": "", "text": "床铺底下压着东西。你伸手去够——"},
				{"name": "丙七", "text": "那底下没什么。"},
			])

	_busy = false


func _on_socket_pressed(socket: InkSpot) -> void:
	if _busy or _lit:
		return
	_busy = true

	var item := socket.label_text
	if not _bag.has(item):
		await _say([{"name": "", "text": "没有%s。" % item}])
		_busy = false
		return

	_placed[item] = true
	socket.used = true
	await _say([{"name": "", "text": "放上了%s。" % item}])

	if _placed.has("火种") and _placed.has("灯芯"):
		_lit = true
		queue_redraw()

	_busy = false


# ---------------------------------------------------------------- 等待

func _await_wick() -> void:
	while true:
		await get_tree().create_timer(0.1).timeout
		if _bag.has("灯芯") and _spots[0].used:
			return


func _await_lit() -> void:
	while not _lit:
		await get_tree().create_timer(0.1).timeout


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * LAMP_Y)

	# 灯座
	InkBrush.ring(self, center, 42.0, Color(INK.r, INK.g, INK.b, 0.45), 2.2)
	draw_circle(center, 36.0, Color(INK.r, INK.g, INK.b, 0.06))

	if _lit:
		# 昏黄的光：几层由内到外越来越淡的暖色
		draw_circle(center, 128.0, Color(COLOR_WARM.r, COLOR_WARM.g, COLOR_WARM.b, 0.05))
		draw_circle(center, 76.0, Color(COLOR_WARM.r, COLOR_WARM.g, COLOR_WARM.b, 0.08))
		draw_circle(center, 38.0, Color(COLOR_WARM.r, COLOR_WARM.g, COLOR_WARM.b, 0.14))
		draw_circle(center, 11.0, Color(1.0, 0.86, 0.60, 0.90))
	else:
		var font := get_theme_default_font()
		if font != null:
			var text := "灯 盏"
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(
				font,
				center + Vector2(-width * 0.5, 6.0),
				text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				20,
				Color(INK_SOFT.r, INK_SOFT.g, INK_SOFT.b, 0.55)
			)


# ---------------------------------------------------------------- 工具

func _say(lines: Array) -> void:
	_dialogue.play(lines)
	await _dialogue.sequence_finished
