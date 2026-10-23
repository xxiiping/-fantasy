class_name ChapterCard
extends Control

## 章节标题卡。
##
## 分镜里写的是"海图推镜 + 标题"，海图还没做，先出标题卡。
## 节奏：纸面淡入 → 标题浮现 → 停一拍 → 整体淡出，不留黑屏。

const PAPER := Color(0.925, 0.898, 0.847)
const INK := Color(0.10, 0.10, 0.12)
const INK_SOFT := Color(0.34, 0.33, 0.35)

var _bg: ColorRect
var _title: Label
var _subtitle: Label
var _quote: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = PAPER
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = -60.0
	box.offset_bottom = 60.0

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", INK)
	box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 24)
	_subtitle.add_theme_color_override("font_color", INK_SOFT)
	box.add_child(_subtitle)

	_quote = Label.new()
	_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote.add_theme_font_size_override("font_size", 19)
	_quote.add_theme_color_override("font_color", Color(INK_SOFT.r, INK_SOFT.g, INK_SOFT.b, 0.75))
	box.add_child(_quote)


## 播一张卡。会等到它淡出结束才返回。
func play(title: String, subtitle: String, quote: String, hold := 1.5) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_quote.text = quote

	visible = true
	modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)
	tween.tween_interval(hold)
	tween.tween_property(self, "modulate:a", 0.0, 0.7)
	await tween.finished

	visible = false
