class_name GameState
extends RefCounted

## 纯规则状态机。
##
## 刻意不继承 Node，理由：
##   1. 不进场景树 —— 树的增删、pause、queue_free 都不应影响规则
##   2. RefCounted 可在 headless / 编辑器环境里单测
##   3. GameState.new() 即一次干净复位，结构上排除"重启漏清字段"
##   4. 不持有任何节点引用，没有悬空风险
##
## 判定逻辑全部收在这里，UI 一行判定都不写。
## push_rune() 返回结构化结果，由 UI 负责翻译成表现。

enum Phase { STORY, PUZZLE, ENDING }
enum Outcome { NONE, SUCCESS, FAILURE }

const DEFAULT_TARGET := [&"star", &"tide", &"wind"]
const DEFAULT_MAX_ATTEMPTS := 2


## push_rune() 的结构化返回值。UI 只读这些字段，不读 GameState 内部状态。
class PushResult:
	var accepted := false      ## 是否被接受（结算后一律 false）
	var judged := false        ## 本次是否触发了判定
	var success := false       ## 判定且正确
	var cleared := false       ## 是否清空了已输入
	var settled := false       ## 本次是否产生了最终结算
	var attempts_left := 0     ## 判定后的剩余次数
	var input_size := 0        ## 本次操作后的已输入数量

	func _to_string() -> String:
		return "PushResult(accepted=%s judged=%s success=%s cleared=%s settled=%s left=%d size=%d)" % [
			accepted, judged, success, cleared, settled, attempts_left, input_size,
		]


var phase: Phase = Phase.STORY
var hint_enabled := false
var outcome: Outcome = Outcome.NONE
var settled := false

var input: Array[StringName] = []
var target: Array[StringName] = []
var max_attempts := DEFAULT_MAX_ATTEMPTS
var attempts_left := DEFAULT_MAX_ATTEMPTS
## 番外专用：判错不扣次数、永不结算。第一阶段恒为 false。
var unlimited_attempts := false


func _init(p_target: Array = [], p_max_attempts: int = DEFAULT_MAX_ATTEMPTS, p_unlimited := false) -> void:
	var source: Array = p_target if not p_target.is_empty() else DEFAULT_TARGET
	target.clear()
	for rune_id in source:
		target.append(StringName(rune_id))
	if target.is_empty():
		# 兜底：目标序列为空会让"满员判定"永远不触发，退回默认值
		for rune_id in DEFAULT_TARGET:
			target.append(StringName(rune_id))
	max_attempts = maxi(1, p_max_attempts)
	attempts_left = max_attempts
	unlimited_attempts = p_unlimited


## 玩家选定剧情选项后进入谜题。hint 由选项决定，本局内不再改变。
func begin(hint: bool) -> void:
	hint_enabled = hint
	phase = Phase.PUZZLE


## 是否还能接受符文输入。结算后、非谜题阶段一律为 false。
func can_accept_input() -> bool:
	return phase == Phase.PUZZLE and not settled and outcome == Outcome.NONE


## 需要几枚符文才判定。
func required_count() -> int:
	return target.size()


## 推入一枚符文。返回值描述这一步发生了什么，调用方据此驱动表现。
func push_rune(rune_id: StringName) -> PushResult:
	var res := PushResult.new()
	res.attempts_left = attempts_left
	res.input_size = input.size()

	if not can_accept_input():
		return res

	res.accepted = true
	input.append(rune_id)
	res.input_size = input.size()

	# 未满员：继续等输入，不判定
	if input.size() < target.size():
		return res

	# 满员：判定，且本次调用内只判定一次
	res.judged = true

	if input == target:
		outcome = Outcome.SUCCESS
		settled = true
		phase = Phase.ENDING
		res.success = true
		res.settled = true
		res.attempts_left = attempts_left
		return res

	# 判错：先清空输入
	input.clear()
	res.cleared = true
	res.input_size = 0

	# 番外：错了不罚，永远不结算，可以一直试
	if unlimited_attempts:
		res.attempts_left = attempts_left
		return res

	attempts_left -= 1
	res.attempts_left = attempts_left

	if attempts_left <= 0:
		outcome = Outcome.FAILURE
		settled = true
		phase = Phase.ENDING
		res.settled = true

	return res


## 回到初始状态。等价于 new()，但保留实例便于调试桥引用。
func reset() -> void:
	phase = Phase.STORY
	hint_enabled = false
	outcome = Outcome.NONE
	settled = false
	input.clear()
	attempts_left = max_attempts


## 只读快照，供单测与调试桥使用。
func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"hint_enabled": hint_enabled,
		"input": input.duplicate(),
		"attempts_left": attempts_left,
		"outcome": outcome,
		"settled": settled,
	}
