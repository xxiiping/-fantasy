extends Node

## 主场景根：只做两件事 —— 监听阶段变化、换屏。
## 不持有规则，不判断对错。

const STORY_SCENE := preload("res://scenes/screens/story_view.tscn")
const PUZZLE_SCENE := preload("res://scenes/screens/rune_puzzle.tscn")
const ENDING_SCENE := preload("res://scenes/screens/ending_view.tscn")
const EPILOGUE_SCENE := preload("res://scenes/screens/epilogue_view.tscn")

@onready var flow: GameFlow = $GameFlow
@onready var host: Control = $ScreenLayer/Host
@onready var backdrop: BackdropView = $Backdrop/BackdropView

var _screen: Node = null


func _ready() -> void:
	# 界面按 1280×720 设计，面板有固定最小宽度。
	# 窗口被拉得比这还小时，容器不会自动缩放，文字会被裁掉 —— 所以兜一个下限。
	var window := get_window()
	if window != null:
		window.min_size = Vector2i(1024, 576)

	flow.stage_changed.connect(_on_stage_changed)
	_maybe_attach_debug_bridge()
	flow.start()


## 调试桥只在 debug 构建里动态挂载，导出包内不存在该节点
func _maybe_attach_debug_bridge() -> void:
	if not OS.is_debug_build():
		return
	var bridge := DebugBridge.new()
	bridge.name = "DebugBridge"
	bridge.flow = flow
	bridge.host = host
	add_child(bridge)


func _on_stage_changed(stage: int) -> void:
	match stage:
		GameFlow.Stage.STORY:
			_show_story()
		GameFlow.Stage.DIALOGUE:
			_show_dialogue()
		GameFlow.Stage.PUZZLE:
			_show_puzzle()
		GameFlow.Stage.ENDING:
			_show_ending()


# ---------------------------------------------------------------- 换屏

func _swap(screen: Node) -> void:
	if _screen != null and is_instance_valid(_screen):
		if _screen.get_parent() == host:
			host.remove_child(_screen)
		_screen.queue_free()
	_screen = screen
	host.add_child(screen)


# ---------------------------------------------------------------- 四个界面

func _show_story() -> void:
	backdrop.reset_visuals()
	var view := STORY_SCENE.instantiate()
	_swap(view)
	view.chosen.connect(_on_story_chosen)


func _show_dialogue() -> void:
	var view := EPILOGUE_SCENE.instantiate()
	_swap(view)
	view.finished.connect(_on_dialogue_finished)


func _show_puzzle() -> void:
	var view := PUZZLE_SCENE.instantiate()
	_swap(view)
	view.configure(
		flow.active_config,
		flow.state,
		flow.state.hint_enabled,
		flow.is_epilogue_puzzle(),
	)
	view.completed.connect(_on_puzzle_completed)
	view.solved.connect(_on_puzzle_solved)
	view.mistake_made.connect(_on_puzzle_mistake)


func _show_ending() -> void:
	var view := ENDING_SCENE.instantiate()
	_swap(view)
	view.present(flow.state.outcome, flow.epilogue_available, flow.is_third_ending())
	view.restart_requested.connect(_on_restart_requested)
	view.extra_requested.connect(_on_extra_requested)


# ---------------------------------------------------------------- 转发

func _on_story_chosen(hint_enabled: bool) -> void:
	flow.choose(hint_enabled)


func _on_dialogue_finished() -> void:
	flow.start_epilogue_puzzle()


func _on_puzzle_completed(success: bool) -> void:
	flow.on_puzzle_completed(success)


func _on_puzzle_solved() -> void:
	backdrop.celebrate()


func _on_puzzle_mistake(_attempts_left: int) -> void:
	backdrop.pulse_wrong()


func _on_restart_requested() -> void:
	flow.restart()


func _on_extra_requested() -> void:
	flow.begin_epilogue()
