extends Control

## 第一章 · 灯塔（垂直切片）
##
## 已接入：宣纸、墨雾、剪影、对话框、选择、符文机关（水墨版）。
## 尚未接入：修缮（1-4）、雾退与第二盏灯（1-5）。

var _backdrop: InkBackdrop
var _dialogue: DialogueBox
var _qi7: InkFigure
var _altar: RuneAltar
var _lamp: DistantLamp
var _card: ChapterCard
var _chosen_hint := false


func _ready() -> void:
	_build()
	await get_tree().process_frame
	await _run()


func _build() -> void:
	_backdrop = InkBackdrop.new()
	_backdrop.name = "Backdrop"
	add_child(_backdrop)
	_full_rect(_backdrop)

	_qi7 = InkFigure.new()
	_qi7.name = "Qi7"
	_qi7.who = InkFigure.Who.QI7
	_qi7.visible = false
	_qi7.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_qi7)
	_qi7.anchor_left = 0.58
	_qi7.anchor_top = 0.18
	_qi7.anchor_right = 0.80
	_qi7.anchor_bottom = 0.84
	_qi7.offset_left = 0.0
	_qi7.offset_top = 0.0
	_qi7.offset_right = 0.0
	_qi7.offset_bottom = 0.0

	_lamp = DistantLamp.new()
	_lamp.name = "DistantLamp"
	_lamp.visible = false
	_lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lamp)
	_lamp.anchor_left = 0.640
	_lamp.anchor_top = 0.26
	_lamp.anchor_right = 0.712
	_lamp.anchor_bottom = 0.56
	_lamp.offset_left = 0.0
	_lamp.offset_top = 0.0
	_lamp.offset_right = 0.0
	_lamp.offset_bottom = 0.0

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
	_backdrop.set_fog_density(0.95, 0.0)

	await _card.play("第一章", "灯　塔", "第七日，雾没有散。")

	await _say([
		{"name": "", "text": "第七日，雾没有散。"},
		{"name": "", "text": "船上有两万七千三百人。\n淡水的账，只剩七天。"},
		{"name": "", "text": "左舷之外，有一点光。一明，一灭。"},
	])

	_backdrop.set_fog_density(0.60, 1.6)
	await _say([
		{"name": "", "text": "塔门透出一点微光。"},
		{"name": "", "text": "守塔人站在门下，手里那盏灯，比塔顶的还要暗。"},
	])

	_qi7.visible = true
	_qi7.modulate.a = 0.0
	create_tween().tween_property(_qi7, "modulate:a", 1.0, 0.6)

	await _say([
		{"name": "丙七", "text": "灯要亮，得先让塔里的三枚符文归位。"},
		{"name": "丙七", "text": "这机关认的不是力气，是道理。"},
		{"name": "丙七", "text": "船过重洋，靠的是什么？\n想起来了，门就开了。"},
	])

	_dialogue.show_choices(PackedStringArray(["请教守塔人", "我自己想"]))
	var picked: int = await _dialogue.choice_picked
	_chosen_hint = picked == 0

	if _chosen_hint:
		await _say([{"name": "丙七", "text": "……那老朽念一句。你记着。"}])
	else:
		await _say([{"name": "丙七", "text": "也好。\n道理是别人的，路是自己的。"}])

	await _run_altar()

	await _say([
		{"name": "", "text": "石盘转了一圈，停住。"},
		{"name": "", "text": "塔身传来一声很长的响，\n像有人松了一口气。"},
	])

	await _run_repair()
	await _run_chapter_end()


## 符文机关。第一章允许无限重试 —— 失败只是丙七说一句话。
func _run_altar() -> void:
	var config := PuzzleLibrary.main_config()
	var success := false

	# 机关占据画面中央，丙七让位
	_qi7.visible = false

	while not success:
		await _dialogue.hide_box()

		var state := GameState.new(config.target_ids(), config.max_attempts)
		state.begin(_chosen_hint)

		_altar = RuneAltar.new()
		_altar.name = "Altar"
		add_child(_altar)
		_full_rect(_altar)
		_altar.configure(config, state, _chosen_hint)
		_altar.mistake.connect(_on_altar_mistake)

		success = await _altar.resolved

		_altar.mistake.disconnect(_on_altar_mistake)
		_altar.queue_free()
		_altar = null

		if not success:
			_qi7.visible = true
			await _say([
				{"name": "丙七", "text": "灭了就再点。海不催你。"},
				{"name": "丙七", "text": "催你的是水。"},
			])
			_qi7.visible = false

	_qi7.visible = true


func _on_altar_mistake(_attempts_left: int) -> void:
	_backdrop.pulse_ink(0.55)


# ---------------------------------------------------------------- 1-4 修缮

func _run_repair() -> void:
	_qi7.visible = false

	var repair := LampRepair.new()
	repair.name = "Repair"
	add_child(repair)
	_full_rect(repair)

	await repair.run(_dialogue)

	repair.queue_free()
	_qi7.visible = true


# ---------------------------------------------------------------- 1-5 雾退

func _run_chapter_end() -> void:
	_backdrop.clear_fog(3.0)

	await _say([
		{"name": "", "text": "昏黄的灯亮起来。\n雾从塔前退开一道缝。"},
	])

	# 缝的尽头浮出另一盏灯 —— 它是灭的，所以只有轮廓
	_lamp.visible = true
	_lamp.reveal_over(2.2)

	await _say([
		{"name": "", "text": "缝的尽头，还有一盏灯。"},
		{"name": "", "text": "灭着。"},
	])

	await _say([
		{"name": "郑和", "text": "那里面有人吗？"},
		{"name": "丙七", "text": "（很久）有。"},
		{"name": "丙七", "text": "所以老朽四十年没点过灯。"},
	])

	await _say([{"name": "", "text": "—— 第一章 · 灯塔 · 完 ——"}])


# ---------------------------------------------------------------- 工具

func _say(lines: Array) -> void:
	_dialogue.play(lines)
	await _dialogue.sequence_finished
