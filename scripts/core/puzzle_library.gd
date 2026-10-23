class_name PuzzleLibrary
extends RefCounted

## 两份谜题配置的唯一来源。
##
## 为什么不做成 .tres：现阶段只有两份配置、文案还在频繁改，
## 代码构建比手写 .tres 更不容易出错，也便于单测直接拿到值。
## PuzzleConfig / RuneDefinition 本身是 Resource，随时可落盘成 .tres。

const RUNE_STAR := &"star"
const RUNE_TIDE := &"tide"
const RUNE_WIND := &"wind"

## 题面给定的提示文案，一个字都不能改。单测逐字比对。
const HINT_TEXT := "星光开航，潮汐同行，最后听风而行。"

const COLOR_STAR := Color("f2c879")
const COLOR_TIDE := Color("6fd3da")
const COLOR_WIND := Color("bfe8d8")


static func star_rune() -> RuneDefinition:
	var rune := RuneDefinition.new()
	rune.id = RUNE_STAR
	rune.display_name = "星象"
	rune.glyph = RuneDefinition.Glyph.STAR
	rune.tint = COLOR_STAR
	rune.stroke_seed = 1013
	return rune


static func tide_rune() -> RuneDefinition:
	var rune := RuneDefinition.new()
	rune.id = RUNE_TIDE
	rune.display_name = "海潮"
	rune.glyph = RuneDefinition.Glyph.TIDE
	rune.tint = COLOR_TIDE
	rune.stroke_seed = 2027
	return rune


static func wind_rune() -> RuneDefinition:
	var rune := RuneDefinition.new()
	rune.id = RUNE_WIND
	rune.display_name = "季风"
	rune.glyph = RuneDefinition.Glyph.WIND
	rune.tint = COLOR_WIND
	rune.stroke_seed = 3041
	return rune


static func all_runes() -> Array[RuneDefinition]:
	return [star_rune(), tide_rune(), wind_rune()]


## 第一阶段的谜题：正确顺序 星 → 潮 → 风，2 次验证机会。
static func main_config() -> PuzzleConfig:
	var config := PuzzleConfig.new()
	config.title = "符文机关"
	config.prompt = "按你心里的道理，依次点亮三枚符文。"
	config.runes = all_runes()
	config.target_sequence = PackedStringArray(["star", "tide", "wind"])
	config.max_attempts = 2
	config.unlimited_attempts = false
	config.hint_text = HINT_TEXT
	config.feedback_correct = "机关认得这条路。"
	config.feedback_wrong = "符文亮了，又灭了。塔身轻轻晃了一下。"
	config.feedback_failed = "三声呼吸之后，机关彻底暗了下去。"
	return config


## 番外的反向谜题：当年他排的次序是 星 → 风 → 潮。
## 不限次数 —— 这是复盘，不是考试。
static func epilogue_config() -> PuzzleConfig:
	var config := PuzzleConfig.new()
	config.title = "第二夜 · 重演"
	config.prompt = "把那年他做的次序，走一遍。"
	config.runes = all_runes()
	config.target_sequence = PackedStringArray(["star", "wind", "tide"])
	config.max_attempts = 2
	config.unlimited_attempts = true
	config.hint_text = ""
	config.feedback_correct = "机关亮了。这一次，塔身在响。"
	config.feedback_wrong = "不是这个次序。他没有这么做过。"
	config.feedback_failed = ""
	return config
