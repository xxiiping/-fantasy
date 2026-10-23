class_name Sfx
extends RefCounted

## 音效的薄代理层。
##
## 为什么不直接写 AudioManager.play_click()：
## AutoLoad 的全局标识符是在 GDScript 编译期解析的，运行中新增 autoload
## 后编辑器不会立刻认识这个名字，会报 "Identifier not found: AudioManager"。
## 走运行时的 /root 查找既不依赖编译期，也让 UI 不必知道单例叫什么。

static var _manager: Node = null


static func _get_manager() -> Node:
	if _manager != null and is_instance_valid(_manager):
		return _manager
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	_manager = tree.root.get_node_or_null("AudioManager")
	return _manager


static func click() -> void:
	var manager := _get_manager()
	if manager != null:
		manager.play_click()


static func correct() -> void:
	var manager := _get_manager()
	if manager != null:
		manager.play_correct()


static func wrong() -> void:
	var manager := _get_manager()
	if manager != null:
		manager.play_wrong()
