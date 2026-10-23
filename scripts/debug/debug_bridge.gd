class_name DebugBridge
extends Node

## 只在 OS.is_debug_build() 为真时由 Main 动态挂载，导出包里不存在。
##
## 作用：让验收脚本把游戏推到某个确定状态，截图不靠"一路点过去"。
## 注意：这里的 goto 只改变"在哪一屏"和"state 的值"，
## 判定本身仍然走 GameState.push_rune —— 它不会绕过任何规则。

var flow: GameFlow
var host: Control


# ---------------------------------------------------------------- 状态跳转

func goto(preset: String) -> bool:
	match preset:
		"story_initial":
			flow.start()
			return true
		"story_choice_a":
			flow.choose(true)
			return true
		"story_choice_b":
			flow.choose(false)
			return true

		"puzzle_one":
			flow.choose(true)
			return press_rune(&"star")

		"puzzle_two":
			flow.choose(true)
			return press_rune(&"star") and press_rune(&"tide")

		"puzzle_wrong_1":
			flow.choose(true)
			press_rune(&"star")
			press_rune(&"wind")
			return press_rune(&"tide")

		"ending_success":
			return _force_ending(&"success")

		"ending_failure":
			return _force_ending(&"failure")

		"ending_restart":
			if not _force_ending(&"success"):
				return false
			flow.restart()
			return true

		"epilogue_dialogue":
			if not _force_ending(&"success"):
				return false
			flow.begin_epilogue()
			return true

		"epilogue_puzzle":
			if not goto("epilogue_dialogue"):
				return false
			flow.start_epilogue_puzzle()
			return true

		"ending_third":
			if not goto("epilogue_puzzle"):
				return false
			var epilogue_state := flow.state
			epilogue_state.push_rune(&"star")
			epilogue_state.push_rune(&"wind")
			epilogue_state.push_rune(&"tide")
			if not epilogue_state.settled:
				return false
			flow.on_puzzle_completed(true)
			return true

	return false


## 走真实点击路径（与玩家点击同一个入口）
func press_rune(rune_id: StringName) -> bool:
	var screen := current_screen()
	if screen is RunePuzzle:
		screen.press(rune_id)
		return true
	return false


# ---------------------------------------------------------------- 读数

func current_screen() -> Node:
	if host == null:
		return null
	for child in host.get_children():
		return child
	return null


func snapshot() -> Dictionary:
	var screen := current_screen()
	var state_snapshot := {}
	if flow != null and flow.state != null:
		state_snapshot = flow.state.snapshot()
	return {
		"screen": String(screen.name) if screen != null else "",
		"state": state_snapshot,
		"mode": flow.mode if flow != null else -1,
		"epilogue_available": flow.epilogue_available if flow != null else false,
	}


# ---------------------------------------------------------------- 内部

## 结局预设：判定仍然走 GameState.push_rune，只跳过 0.9 秒的过场等待
func _force_ending(target: StringName) -> bool:
	flow.choose(true)
	var state := flow.state

	if target == &"success":
		state.push_rune(&"star")
		state.push_rune(&"tide")
		state.push_rune(&"wind")
	else:
		for i in 2:
			state.push_rune(&"tide")
			state.push_rune(&"wind")
			state.push_rune(&"star")

	if not state.settled:
		return false

	flow.on_puzzle_completed(state.outcome == GameState.Outcome.SUCCESS)
	return true
