class_name RunePuzzle
extends Control

## 符文小游戏。第一阶段与番外共用这一个场景：
## 符文、目标、次数、文案全部来自 PuzzleConfig，判定全部来自 GameState。
## 本文件里没有任何一行"对/错"的判断。

signal completed(success: bool)
## 判定成功的那一刻（早于 completed 的 0.9 秒过场等待）
signal solved()
## 判错一次。带剩余次数，供背景层决定雾要收多紧。
signal mistake_made(attempts_left: int)

const RUNE_BUTTON_SCENE := preload("res://scenes/ui/rune_button.tscn")

const COLOR_GOOD := Color("f2c879")
const COLOR_BAD := Color("e2704a")

@onready var title_label: Label = %Title
@onready var prompt_label: Label = %Prompt
@onready var hint_panel: PanelContainer = %HintPanel
@onready var hint_label: RichTextLabel = %HintLabel
@onready var rune_row: HBoxContainer = %RuneRow
@onready var slot_row: HBoxContainer = %SlotRow
@onready var lamp_row: HBoxContainer = %Lamps
@onready var attempts_label: Label = %AttemptsLabel
@onready var feedback_label: Label = %Feedback

var config: PuzzleConfig
var state: GameState
var hint_enabled := false
var is_epilogue := false

var _slots: Array[RuneSlot] = []
var _lamps: Array[AttemptLamp] = []
var _buttons: Dictionary = {}
var _locked := false
var _finishing := false


func _ready() -> void:
	if config != null:
		_build()


## 由 Main 在实例化后调用
func configure(p_config: PuzzleConfig, p_state: GameState, p_hint: bool, p_epilogue: bool) -> void:
	config = p_config
	state = p_state
	hint_enabled = p_hint
	is_epilogue = p_epilogue
	if is_node_ready():
		_build()


# ---------------------------------------------------------------- 构建

func _build() -> void:
	title_label.text = config.title
	prompt_label.text = config.prompt

	# 提示：必须"选 A 且有文案"才显示；否则连文本一起清掉，不留残留
	var show_hint := hint_enabled and not config.hint_text.is_empty()
	hint_panel.visible = show_hint
	hint_label.text = config.hint_text if show_hint else ""

	_build_rune_buttons()
	_build_slots()
	_build_lamps()

	feedback_label.text = ""
	_refresh()

	# 番外是"回忆"：整体偏暖一档，和第一阶段的冷色区分开
	if is_epilogue:
		modulate = Color(1.0, 0.93, 0.86, 1.0)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _build_rune_buttons() -> void:
	for child in rune_row.get_children():
		rune_row.remove_child(child)
		child.queue_free()
	_buttons.clear()

	for rune in config.runes:
		var button := RUNE_BUTTON_SCENE.instantiate()
		rune_row.add_child(button)
		button.setup(rune)
		button.rune_pressed.connect(_on_rune_pressed)
		_buttons[rune.id] = button


func _build_slots() -> void:
	for child in slot_row.get_children():
		slot_row.remove_child(child)
		child.queue_free()
	_slots.clear()

	for i in state.required_count():
		var slot := RuneSlot.new()
		slot_row.add_child(slot)
		_slots.append(slot)


func _build_lamps() -> void:
	for child in lamp_row.get_children():
		lamp_row.remove_child(child)
		child.queue_free()
	_lamps.clear()

	# 不限次数时不摆灯：摆两盏灯再写"不限次数"只会让人以为还有两盏的额度
	if state.unlimited_attempts:
		return

	for i in state.max_attempts:
		var lamp := AttemptLamp.new()
		lamp_row.add_child(lamp)
		_lamps.append(lamp)


# ---------------------------------------------------------------- 交互

## 公开的"按下一枚符文"入口。玩家点击、调试桥、将来可能的键盘操作
## 都走这一条路径，保证行为完全一致。
func press(rune_id: StringName) -> void:
	_on_rune_pressed(rune_id)


func _on_rune_pressed(rune_id: StringName) -> void:
	if _locked or state == null or not state.can_accept_input():
		return

	var result := state.push_rune(rune_id)
	_refresh()
	if not result.judged:
		return

	if result.success:
		_show_feedback(config.feedback_correct, COLOR_GOOD)
		Sfx.correct()
		solved.emit()
		_finish(true)
	elif result.settled:
		var text := config.feedback_failed
		if text.is_empty():
			text = config.feedback_wrong
		_show_feedback(text, COLOR_BAD)
		Sfx.wrong()
		mistake_made.emit(state.attempts_left)
		_finish(false)
	else:
		# 还有次数（或番外不限次数）：清空后继续
		_show_feedback(config.feedback_wrong, COLOR_BAD)
		Sfx.wrong()
		mistake_made.emit(state.attempts_left)


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color


func _finish(success: bool) -> void:
	if _finishing:
		return
	_finishing = true
	_locked = true

	for button in _buttons.values():
		if is_instance_valid(button):
			button.disabled = true

	await get_tree().create_timer(0.9).timeout
	if is_inside_tree():
		completed.emit(success)


# ---------------------------------------------------------------- 刷新

func _refresh() -> void:
	for i in _slots.size():
		var slot := _slots[i]
		if i < state.input.size():
			var rune := config.rune_by_id(state.input[i])
			if rune != null:
				slot.set_rune(rune.display_name, rune.tint)
			else:
				slot.set_rune(String(state.input[i]), Color.WHITE)
		else:
			slot.clear()

	for i in _lamps.size():
		_lamps[i].set_lit(i < state.attempts_left)

	if state.unlimited_attempts:
		attempts_label.text = "不限次数"
	else:
		attempts_label.text = "余 %d 次" % state.attempts_left
