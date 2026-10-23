class_name GameFlow
extends Node

## 流程编排：持有 GameState，负责阶段切换与配置选择。
## 屏幕本身不决定流程，只负责"显示"和"把用户动作发上来"。
##
## 注意 Stage 与 GameState.Phase 是两层东西：
##   GameState.Phase —— 规则层面（剧本/谜题/结算），只有三个阶段
##   GameFlow.Stage  —— 屏幕层面，番外多一个对话屏
## 混用会把 UI 状态写进规则枚举，后面很难看。

signal stage_changed(stage: int)

enum Stage { STORY, DIALOGUE, PUZZLE, ENDING }
enum Mode { MAIN, EPILOGUE }

var state: GameState
var active_config: PuzzleConfig
var mode: Mode = Mode.MAIN

## 番外入口是否开放（只在第一阶段成功时开放）
var epilogue_available := false


func _ready() -> void:
	state = GameState.new()


## 开场 / 重新开始：一切都从全新的 state 开始
func start() -> void:
	var config := PuzzleLibrary.main_config()
	mode = Mode.MAIN
	epilogue_available = false
	active_config = config
	state = GameState.new(config.target_ids(), config.max_attempts)
	state.phase = GameState.Phase.STORY
	stage_changed.emit(Stage.STORY)


## 剧情选项
func choose(hint_enabled: bool) -> void:
	if state.phase != GameState.Phase.STORY:
		return
	state.begin(hint_enabled)
	stage_changed.emit(Stage.PUZZLE)


## 小游戏结算（由 RunePuzzle.completed 调用）
func on_puzzle_completed(success: bool) -> void:
	if not state.settled:
		return
	# 只有第一阶段成功，才开放番外
	epilogue_available = success and mode == Mode.MAIN
	stage_changed.emit(Stage.ENDING)


## 结局界面 → 重新开始
func restart() -> void:
	start()


# ---------------------------------------------------------------- 番外

## 结局界面 → 番外入口：先进对话，不直接进谜题
func begin_epilogue() -> void:
	if not epilogue_available:
		return
	mode = Mode.EPILOGUE
	epilogue_available = false
	stage_changed.emit(Stage.DIALOGUE)


## 对话看完（或跳过）→ 反向谜题
func start_epilogue_puzzle() -> void:
	var config := PuzzleLibrary.epilogue_config()
	active_config = config
	state = GameState.new(config.target_ids(), config.max_attempts, config.unlimited_attempts)
	state.begin(false)
	stage_changed.emit(Stage.PUZZLE)


func is_third_ending() -> bool:
	return mode == Mode.EPILOGUE and state.outcome == GameState.Outcome.SUCCESS


func is_epilogue_puzzle() -> bool:
	return mode == Mode.EPILOGUE
