@tool
extends McpTestSuite

## GameState 的不变量测试。
##
## 覆盖策划案 §3.8 的 12 项验收中，所有"规则层"能测的部分。
## 截图能证明画面长这样，单测能证明规则算得对 —— 两者互补。
##
## 写法约定：每条 test_ 对应一条不变量，失败消息写清"违反了哪条"，
## 不要写 "assert failed" 这种看完还得回头读代码的废话。

const GameStateScript := preload("res://scripts/core/game_state.gd")
const PuzzleLibraryScript := preload("res://scripts/core/puzzle_library.gd")

var _state


func suite_name() -> String:
	return "game_state"


func setup() -> void:
	_state = GameStateScript.new()


func teardown() -> void:
	_state = null


# ---------------------------------------------------------------- 配置

func test_00_config_sanity() -> void:
	var config = PuzzleLibraryScript.main_config()
	assert_eq(config.target_sequence, PackedStringArray(["star", "tide", "wind"]), "正确顺序必须是 星→潮→风")
	assert_eq(config.max_attempts, 2, "第一阶段必须是 2 次验证机会")
	assert_false(config.unlimited_attempts, "第一阶段不能是不限次数")
	assert_eq(config.runes.size(), 3, "必须恰好三枚符文")


# ------------------------------------------------- 不变量 1：不足 3 枚不判定

func test_01_insufficient_input_does_not_judge() -> void:
	_state.begin(false)
	var r1 = _state.push_rune(&"star")
	assert_true(r1.accepted, "首枚符文应被接受")
	assert_false(r1.judged, "只输入 1 枚就判定 = 违反不变量 1")
	assert_eq(_state.input.size(), 1)

	var r2 = _state.push_rune(&"tide")
	assert_false(r2.judged, "只输入 2 枚就判定 = 违反不变量 1")
	assert_eq(_state.input.size(), 2)
	assert_eq(_state.outcome, GameStateScript.Outcome.NONE, "未满员不应产生任何结论")


# ------------------------------------------------- 不变量 2：满 3 枚判定一次

func test_02_full_input_judges_once() -> void:
	_state.begin(false)
	_state.push_rune(&"star")
	_state.push_rune(&"tide")
	var r = _state.push_rune(&"wind")

	assert_true(r.judged, "第 3 枚必须触发判定")
	assert_true(r.success)
	assert_eq(_state.outcome, GameStateScript.Outcome.SUCCESS)

	# 同一帧内可能连点，必须只判定一次
	var again = _state.push_rune(&"star")
	assert_false(again.accepted, "结算后连点必须被拒绝")
	assert_false(again.judged, "不得二次判定")


# ------------------------------------------------- 不变量 5a：正确即成功

func test_03_correct_ends_in_success() -> void:
	_state.begin(false)
	_state.push_rune(&"star")
	_state.push_rune(&"tide")
	_state.push_rune(&"wind")

	assert_eq(_state.outcome, GameStateScript.Outcome.SUCCESS, "正确序列必须成功")
	assert_true(_state.settled, "成功后必须已结算")
	assert_eq(_state.attempts_left, 2, "通关不应消耗机会")
	assert_false(_state.can_accept_input(), "结算后不得再接受输入")
	assert_eq(_state.phase, GameStateScript.Phase.ENDING)


# ------------------------------------------------- 不变量 3：错误清空 + 扣次数

func test_04_wrong_clears_input_and_decrements() -> void:
	_state.begin(false)
	_state.push_rune(&"star")
	_state.push_rune(&"wind")
	var r = _state.push_rune(&"tide")  # 星→风→潮 ≠ 星→潮→风

	assert_true(r.judged, "满 3 枚即使错了也必须判定")
	assert_false(r.success)
	assert_true(r.cleared, "判错后必须清空当前输入")
	assert_eq(_state.input.size(), 0, "判错后输入应为空")
	assert_eq(_state.attempts_left, 1, "第 1 次错后应剩 1 次")
	assert_eq(_state.outcome, GameStateScript.Outcome.NONE, "还有次数时不应结算")
	assert_false(_state.settled, "还有次数时不应结算")
	assert_true(_state.can_accept_input(), "还有次数时必须能继续输入")


# ------------------------------------------------- 不变量 4：连续 2 错即失败

func test_05_second_wrong_ends_in_failure() -> void:
	_state.begin(false)

	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	var first = _state.push_rune(&"star")
	assert_false(first.settled, "第 1 次错不应结算")
	assert_eq(_state.attempts_left, 1)

	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	var second = _state.push_rune(&"star")

	assert_true(second.judged, "第 2 次错也必须判定")
	assert_true(second.settled, "连续 2 次错误必须结算")
	assert_eq(_state.outcome, GameStateScript.Outcome.FAILURE, "连续 2 次错误必须失败")
	assert_eq(_state.attempts_left, 0, "失败后次数必须归零")
	assert_false(_state.can_accept_input(), "失败后不得接受输入")

	# 关键：不存在第 3 次输入
	var third = _state.push_rune(&"star")
	assert_false(third.accepted, "失败后出现第 3 次输入 = 把 2 次机会做成了 3 次")


# ------------------------------------------------- 不变量 6：结算后幂等

func test_06_settled_blocks_all_input() -> void:
	_state.begin(false)
	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	_state.push_rune(&"star")
	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	_state.push_rune(&"star")
	assert_true(_state.settled)

	var before = _state.snapshot()
	for i in 5:
		var r = _state.push_rune(&"star")
		assert_false(r.accepted, "结算后任何输入都必须被拒绝")
	var after = _state.snapshot()
	assert_eq(after, before, "结算后的连续点击不得改变任何状态")


# ------------------------------------------------- 不变量 7：reset 全字段复位

func test_07_reset_restores_every_field() -> void:
	var pristine = GameStateScript.new().snapshot()

	_state.begin(true)
	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	_state.push_rune(&"star")
	_state.push_rune(&"tide")
	_state.push_rune(&"wind")
	_state.push_rune(&"star")
	assert_true(_state.settled, "先造出一个已结算的脏状态")

	_state.reset()
	assert_eq(_state.snapshot(), pristine, "reset 后必须与全新实例完全一致（漏清任一字段都会失败）")


# ------------------------------------------------- 不变量 8：提示只由选项决定

func test_08_hint_flag_only_set_by_begin() -> void:
	assert_false(_state.hint_enabled, "初始不应有提示")
	_state.begin(true)
	assert_true(_state.hint_enabled, "选 A 必须有提示")
	_state.reset()
	assert_false(_state.hint_enabled, "复位后提示必须关掉")

	_state.begin(false)
	assert_false(_state.hint_enabled, "选 B 不得有提示")
	_state.reset()
	assert_false(_state.hint_enabled)


# ------------------------------------------------- 文案锁：题面原文逐字比对

func test_09_hint_text_matches_spec() -> void:
	var config = PuzzleLibraryScript.main_config()
	assert_eq(
		config.hint_text,
		"星光开航，潮汐同行，最后听风而行。",
		"提示文案被改写了。题面原文必须逐字一致，这是判分项。"
	)


# ------------------------------------------------- 番外配置

func test_10_epilogue_config() -> void:
	var config = PuzzleLibraryScript.epilogue_config()
	assert_eq(config.target_sequence, PackedStringArray(["star", "wind", "tide"]), "番外目标序列应为 星→风→潮")
	assert_true(config.unlimited_attempts, "番外必须不限次数")
	assert_eq(config.hint_text, "", "番外不提供提示")
	assert_eq(config.runes.size(), 3, "番外复用同一批三枚符文")

	var cfg_main = PuzzleLibraryScript.main_config()
	assert_ne(config.target_sequence, cfg_main.target_sequence, "番外目标不能与第一阶段相同")


# ------------------------------------------------- 番外：不限次数

func test_11_unlimited_attempts_never_fails() -> void:
	var config = PuzzleLibraryScript.epilogue_config()
	var state = GameStateScript.new(config.target_ids(), config.max_attempts, config.unlimited_attempts)

	state.begin(false)
	# 连错 5 次都必须还能继续
	for i in 5:
		state.push_rune(&"tide")
		var r = state.push_rune(&"wind")
		var res = state.push_rune(&"star")
		assert_true(res.judged, "满 3 枚仍要判定")
		assert_false(res.settled, "番外判错不得结算（这是复盘，不是考试）")
		assert_eq(state.attempts_left, 2, "番外判错不得扣次数")

	assert_eq(state.outcome, GameStateScript.Outcome.NONE, "番外不应产生失败结论")
	assert_true(state.can_accept_input(), "番外必须能一直试下去")

	# 答对仍然要成功
	state.push_rune(&"star")
	state.push_rune(&"wind")
	var ok = state.push_rune(&"tide")
	assert_true(ok.settled, "番外答对必须结算")
	assert_eq(state.outcome, GameStateScript.Outcome.SUCCESS)
