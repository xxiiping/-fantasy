extends Control

## 第二章 · 残骸（2-1 / 2-2）
##
## 目前只做"看到"的部分：雾里的船、甲板上循环重演的回声。
## 打捞（2-3）与变形谜题（2-5）下一轮接。

var _backdrop: InkBackdrop
var _dialogue: DialogueBox
var _card: ChapterCard
var _hull: WreckHull
var _echoes: Array[InkFigure] = []

const ECHO_X := [0.22, 0.33, 0.45, 0.57, 0.68, 0.78]
## 身高略有差异 —— 一样高会像一排墓碑，有纵深才像甲板上的人
const ECHO_H := [0.29, 0.31, 0.27, 0.32, 0.28, 0.26]


func _ready() -> void:
	_build()
	await get_tree().process_frame
	await _run()


func _build() -> void:
	_backdrop = InkBackdrop.new()
	_backdrop.name = "Backdrop"
	add_child(_backdrop)
	_full_rect(_backdrop)
	_backdrop.set_fog_density(1.05, 0.0)

	_hull = WreckHull.new()
	_hull.name = "Hull"
	_hull.visible = false
	_hull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hull)
	_full_rect(_hull)

	# 甲板上的回声：位置固定，姿态同步
	for i in ECHO_X.size():
		var echo := InkFigure.new()
		echo.name = "Echo%d" % i
		echo.who = InkFigure.Who.ZHENGHE
		echo.body_height = ECHO_H[i]
		echo.head_scale = 0.95
		echo.visible = false
		echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 郑和看他们只是模糊的墨团
		echo.ink = Color(0.16, 0.16, 0.18)
		echo.modulate = Color(1, 1, 1, 0.62)
		add_child(echo)
		var x: float = ECHO_X[i]
		echo.anchor_left = x - 0.035
		echo.anchor_right = x + 0.035
		echo.anchor_top = 0.26
		echo.anchor_bottom = 0.565
		echo.offset_left = 0.0
		echo.offset_top = 0.0
		echo.offset_right = 0.0
		echo.offset_bottom = 0.0
		_echoes.append(echo)

	_dialogue = DialogueBox.new()
	_dialogue.name = "Dialogue"
	add_child(_dialogue)
	_full_rect(_dialogue)

	_card = ChapterCard.new()
	_card.name = "ChapterCard"
	add_child(_card)
	_full_rect(_card)


func _full_rect(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ---------------------------------------------------------------- 流程

func _run() -> void:
	await _card.play("第二章", "残　骸", "雾里横着一条船。")

	await _say([
		{"name": "", "text": "雾里横着一艘商船。\n桅杆断了一半。"},
		{"name": "", "text": "船身没有腐烂。"},
	])

	# 船与回声浮现
	_hull.visible = true
	_hull.reveal = 0.0
	create_tween().tween_property(_hull, "reveal", 1.0, 2.0)

	await _say([
		{"name": "郑和", "text": "……这条船，在这儿多久了？"},
	])

	# 所有人一起浮现 —— 只给第一个做补间会让其余停在 0
	for echo in _echoes:
		echo.visible = true
		echo.modulate.a = 0.0
		var fade := echo.create_tween()
		fade.tween_property(echo, "modulate:a", 0.62, 1.2)

	await get_tree().create_timer(1.2).timeout

	# 全体同步 —— 不对相位，这才是"回声"而不是"人群"
	for echo in _echoes:
		echo.play_echo_loop()

	await _say([
		{"name": "", "text": "甲板上有人。"},
		{"name": "", "text": "他们在做同一件事——\n抬手，回头，拉缆绳。然后重来。"},
		{"name": "郑和", "text": "他们听得见我吗？"},
		{"name": "", "text": "没有人回头。"},
	])

	await _run_salvage()


## 2-3 打捞 + 2-4 船志
func _run_salvage() -> void:
	await _dialogue.hide_box()

	# 打捞时废船与回声让位
	_hull.visible = false
	for echo in _echoes:
		echo.visible = false

	var salvage := Salvage.new()
	salvage.name = "Salvage"
	add_child(salvage)
	_full_rect(salvage)

	salvage.run(_dialogue)
	var found: Dictionary = await salvage.finished

	salvage.queue_free()
	_hull.visible = true
	for echo in _echoes:
		echo.visible = true

	if found.has("船志"):
		await _say([
			{"name": "", "text": "泡开的纸，墨迹化开，只能读出几行。"},
			{"name": "", "text": "「……逆流。潮口只开一刻。」"},
			{"name": "", "text": "「船头转不过来。风要是早半刻就好了。」"},
			{"name": "", "text": "「船长说，先看星。可潮不等人。」"},
			{"name": "", "text": "最后一行边角还有一行更小的字：\n「船上有一名女童。」"},
		])
	else:
		await _say([
			{"name": "", "text": "没有找到船志。"},
			{"name": "郑和", "text": "……只能靠猜了。"},
		])

	await _say([{"name": "", "text": "（下一轮：变形谜题）"}])


# ---------------------------------------------------------------- 工具

func _say(lines: Array) -> void:
	_dialogue.play(lines)
	await _dialogue.sequence_finished
