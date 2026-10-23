class_name PuzzleConfig
extends Resource

## 一道符文谜题的全部配置：文案、符文、目标序列、次数上限。
##
## 第一阶段与番外**共用同一个 rune_puzzle.tscn**，只是喂进两份不同的
## PuzzleConfig —— 判定代码只认这份配置，不认识"第几阶段"。

@export var title: String = ""
@export var prompt: String = ""
@export var runes: Array[RuneDefinition] = []

## 正确答案，按 id 排列，如 ["star", "tide", "wind"]
@export var target_sequence: PackedStringArray = PackedStringArray()

@export var max_attempts: int = 2
## 番外为 true：错了不罚，可以一直试
@export var unlimited_attempts := false

@export var hint_text: String = ""
@export var feedback_correct: String = ""
@export var feedback_wrong: String = ""
@export var feedback_failed: String = ""


## 目标序列转成 StringName 数组，供 GameState 使用
func target_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for rune_id in target_sequence:
		out.append(StringName(rune_id))
	return out


func rune_by_id(rune_id: StringName) -> RuneDefinition:
	for rune in runes:
		if rune != null and rune.id == rune_id:
			return rune
	return null


## 本配置允许的总验证次数。unlimited 时返回一个足够大的值
## （判定层用 unlimited_attempts 短路，这个数字只用于 UI 占位）。
func effective_max_attempts() -> int:
	return max_attempts
