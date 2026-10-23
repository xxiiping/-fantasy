class_name EpilogueView
extends Control

## 番外对话。一次一句，看完（或跳过）后进入反向谜题。
## 属于叙事层，不参与任何判定。

signal finished()

const LINES := [
	"[i]「船可以走了。」[/i]",
	"[i]「可老朽想知道 —— 你为什么是这个次序？」[/i]",
	"[color=#9fb4c0]星定方位，潮定进出，风给船力气。[/color]",
	"[i]「……三十年前，有人也是这么说的。」[/i]",
	"[i]「那晚是落潮。出港的窗口，只有一刻。」[/i]",
	"[i]「他先算了方位。等他算准，潮已经退了。」[/i]",
	"[i]「船卡在礁口。再也没有回来。」[/i]",
	"[i]「你要是能想明白他错在哪 —— 把这个次序，替老朽走一遍。」[/i]",
]

@onready var line_label: RichTextLabel = %Line
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton

var _index := 0
var _done := false


func _ready() -> void:
	next_button.pressed.connect(_advance)
	skip_button.pressed.connect(_finish)
	_show_line(0)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.45)


func _show_line(index: int) -> void:
	_index = index
	line_label.text = LINES[index]
	var is_last := index >= LINES.size() - 1
	next_button.text = "进去看看" if is_last else "继续"
	skip_button.text = "跳过"


func _advance() -> void:
	if _done:
		return
	if _index >= LINES.size() - 1:
		_finish()
		return
	_show_line(_index + 1)


func _finish() -> void:
	if _done:
		return
	_done = true
	next_button.disabled = true
	skip_button.disabled = true
	finished.emit()
