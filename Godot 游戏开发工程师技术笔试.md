# Godot 游戏开发工程师技术笔试 - CGGE(Shenzhen)

考生姓名：   测试日期：

答题说明：单选题每题仅选一个答案；代码题使用 GDScript，可分脚本作答；简答题请阐明技术原理与实现思路。

| 考核部分 | 题量 | 分值 |
| --- | --- | --- |
| 一、单选题 | 5 | 25 |
| 二、填空与简答 | 3 | 30 |
| 三、算法与架构设计 | 2 | 30 |
| 四、综合场景分析 | 1 | 15 |
| 合计 | 11 | 100 |

# 一、单选题（每题 5 分，共 25 分）

## 1.  内存管理  （5 分）

在 Godot 4.x 中，以下关于内存管理的描述，错误的是哪一项？

- A. 继承自 RefCounted 的类（如 Resource）主要由引用计数管理生命周期。
- B. Node 不通过引用计数自动回收，可以在其所属父节点释放时连带销毁，也可以调用 queue_free() 或 free() 释放。
- C. queue_free() 通常在当前帧末安全删除节点；free() 会立即释放对象。
- D. 只要一个 Node 通过 remove_child() 从场景树移除，它就会被自动垃圾回收。

## 2.  工作线程与异步计算  （5 分）

需要将耗时的独立计算提交给 Godot 4.x 的内置工作线程池执行，以避免主线程直接执行该计算。以下哪项是正确的提交 API？

- A. Thread.new().start()
- B. WorkerThreadPool.add_task(my_callable)
- C. get_tree().create_timer(0.1)
- D. yield()

## 3.  节点生命周期  （5 分）

当一个节点对象被创建并加入场景树，以下三个生命周期回调的正常触发顺序是：

- A. _init() → _enter_tree() → _ready()
- B. _ready() → _init() → _enter_tree()
- C. _enter_tree() → _init() → _ready()
- D. _init() → _ready() → _enter_tree()

## 4.  大规模对象优化  （5 分）

某弹幕游戏需要更新和渲染数千个具有简单运动与碰撞逻辑的对象。Profiler 已确认：大量 Node 管理和高层物理对象开销构成主要瓶颈。以下哪种方案更适合进一步降低这类开销？

- A. 通过 TileMap 的层级组织所有动态对象。
- B. 使用 RenderingServer 与 PhysicsServer2D 的底层接口组织批量对象。
- C. 将全部敌人的图片合成为一张静态背景图。
- D. 仅将 Thread Model 改为多线程渲染。

## 5.  Signal 连接语法  （5 分）

在 Godot 4.x 中，下列哪一段属于正确、常用的 Button pressed 信号连接语法？

- A. button.connect("pressed", self, "_on_button_pressed")
- B. button.pressed.connect(_on_button_pressed)
- C. button.connect_signal("pressed", _on_button_pressed)
- D. button.pressed = _on_button_pressed

# 二、填空与简答题（每题 10 分，共 30 分）

## 6.  自定义资源注册（填空）  （10 分）

如果一个 GDScript 脚本已继承 Resource，要将它注册为编辑器中可直接选择并新建的自定义资源类型，应使用的关键字是：____________________。

## 7.  帧更新与物理更新  （10 分）

请简述 _process(delta) 和 _physics_process(delta) 的调用时机与主要用途，并说明 CharacterBody2D 的物理运动和碰撞相关逻辑为何通常应放在后者中。回答时请考虑 delta 与不同帧率下运动结果的关系。

## 8.  Node.propagate_call() 的行为  （10 分）

当某个节点调用 propagate_call("method_name") 时，调用范围与执行顺序是什么？请说明 parent_first 参数的作用，以及与向父节点传播的区别。

# 三、算法与架构设计题（每题 15 分，共 30 分）

## 9.  简易背包系统的 Resource 持久化  （15 分）

请用 GDScript 设计一个单机 RPG 的简易背包保存功能：

- 定义名为 InventoryItem 的自定义 Resource，包含物品 ID（int）、数量（int）和名称（String）。
- 设计能够容纳多个 InventoryItem 的背包数据结构。
- 编写管理脚本，通过 ResourceSaver 将完整背包保存到 user://inventory.tres。
- 简要说明读取方式或保存失败时的处理方式。

要求：保存的是完整背包，不能只保存一个物品；可拆分为多个脚本，并写出必要的 GDScript 代码。

## 10.  通用子弹对象池（Object Pool）  （15 分）

某射击游戏频繁创建与销毁子弹导致卡顿。请使用 GDScript 编写一个可复用的对象池管理器，包含以下要求：

- 可以配置 PackedScene 子弹场景；对象不足时实例化新的子弹。
- 提供 get_bullet() 获取可用子弹与 return_bullet(bullet) 回收子弹。
- 回收对象可以被再次使用；重新获取时需恢复必要运行状态。
- 说明如何避免重复回收，并处理可见性、碰撞或运动状态的残留。

可以假定子弹场景具有必要的节点与脚本；请说明你与子弹脚本约定的重置接口。

# 四、综合场景分析题（15 分）

## 11.  500 个商贩 NPC 的性能问题  （15 分）

【场景】一张大地图上有 500 个商贩 NPC。每个 NPC 每隔 3 秒要在本地计算一次随机贸易价格，并根据结果更新头顶的 UI 文本。游戏移动端上线后出现频繁的短时卡顿（Jank / Stutter）。

请作为 Godot 开发工程师，指出至少 3 个可能的性能瓶颈，并针对每个瓶颈提出具体、可执行的 Godot 优化方案。若有必要，可补充你将如何使用 Godot 调试/性能分析工具验证判断。

作答提醒：以具体问题、优化机制及其适用条件为主，允许合理的替代方案。

**—— 试卷结束 ——**
