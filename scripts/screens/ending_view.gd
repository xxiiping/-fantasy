class_name EndingView
extends Control

## 结局界面：成功 / 失败 / 第三结局三套文案，「重新开始」始终是主按钮，
## 番外入口只在第一阶段成功时出现，且是小字次要入口。

signal restart_requested()
signal extra_requested()

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var summary_label: Label = %Summary
@onready var extra_prompt: Label = %ExtraPrompt
@onready var extra_button: Button = %ExtraButton
@onready var restart_button: Button = %RestartButton

var _locked := false


func _ready() -> void:
	restart_button.pressed.connect(_on_restart)
	extra_button.pressed.connect(_on_extra)


func present(outcome: int, epilogue_available: bool, third_ending: bool) -> void:
	if third_ending:
		title_label.text = NarrativeLibrary.ENDING_THIRD_TITLE
		body_label.text = NarrativeLibrary.ENDING_THIRD_BODY
		summary_label.text = NarrativeLibrary.ENDING_THIRD_SUMMARY
	elif outcome == GameState.Outcome.SUCCESS:
		title_label.text = NarrativeLibrary.ENDING_SUCCESS_TITLE
		body_label.text = NarrativeLibrary.ENDING_SUCCESS_BODY
		summary_label.text = NarrativeLibrary.ENDING_SUCCESS_SUMMARY
	else:
		title_label.text = NarrativeLibrary.ENDING_FAILURE_TITLE
		body_label.text = NarrativeLibrary.ENDING_FAILURE_BODY
		summary_label.text = NarrativeLibrary.ENDING_FAILURE_SUMMARY

	# 番外入口：只有第一阶段成功才出现
	extra_prompt.visible = epilogue_available
	extra_button.visible = epilogue_available
	if epilogue_available:
		extra_prompt.text = NarrativeLibrary.EXTRA_PROMPT
		extra_button.text = NarrativeLibrary.EXTRA_LABEL
	else:
		extra_prompt.text = ""
		extra_button.text = ""

	restart_button.text = "重新开始"

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)


func _on_restart() -> void:
	if _locked:
		return
	_locked = true
	Sfx.click()
	restart_requested.emit()


func _on_extra() -> void:
	if _locked:
		return
	_locked = true
	Sfx.click()
	extra_requested.emit()
