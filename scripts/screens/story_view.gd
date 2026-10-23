class_name StoryView
extends Control

## 剧情界面：只负责显示与发出选择，不判断任何规则。

signal chosen(hint_enabled: bool)

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var hint_button: Button = %HintButton
@onready var self_button: Button = %SelfButton

var _locked := false


func _ready() -> void:
	title_label.text = NarrativeLibrary.STORY_TITLE
	body_label.text = NarrativeLibrary.STORY_BODY
	hint_button.text = NarrativeLibrary.CHOICE_HINT
	self_button.text = NarrativeLibrary.CHOICE_SELF

	hint_button.pressed.connect(_choose.bind(true))
	self_button.pressed.connect(_choose.bind(false))

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


func _choose(hint_enabled: bool) -> void:
	# 连点保护：选择只生效一次
	if _locked:
		return
	_locked = true
	hint_button.disabled = true
	self_button.disabled = true
	Sfx.click()
	chosen.emit(hint_enabled)
