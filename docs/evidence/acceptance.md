# 验收记录

> 双轨验收：`截图 + 程序化断言`。
> 截图证明「画面长这样」，`game_eval` 直接读运行中实例的字段证明「状态真是这样」。
> 两者缺一不可 —— 单测管规则，截图管"规则对的结果被人看见"。

- 截图目录：`docs/evidence/screenshots/`
- 单测：`tests/test_game_state.gd`（12 条，75 条断言）

---

## 总览 · 2026-10-23

| 阶段 | 状态 |
| --- | --- |
| M0 骨架 / 规则 / 单测 / 字体 | ✅ |
| M1 三视图 / 流程 / 调试桥 | ✅ |
| M2 视觉层（雾、光柱、程序化符文、主题） | ✅ |
| M3 程序化音频 | ✅ |
| M4 闸门 + 番外（对话 / 反向谜题 / 第三结局） | ✅ |
| M5 README / 流程文档 / 导出 | ✅ |

**第一阶段 12 项验收：12 项全部通过。**

**可执行包已产出并实际启动验证**：`deliverables/ZhengHeFantasy.zip`（57 MB）

---

## 第一阶段 12 项对照

| # | 检查项 | 结果 | 证据 |
| --- | --- | --- | --- |
| 1 | A 路径可见提示，文案逐字一致 | PASS | [S02](screenshots/S02-puzzle-hint.png) + `test_09` 逐字断言 |
| 2 | B 路径完全看不到提示，无残留 | PASS | [S03](screenshots/S03-puzzle-nohint.png) + `hint_visible=false`、`hint_text=""` |
| 3 | 不足 3 枚不判定 | PASS | [S04](screenshots/S04-puzzle-one.png)、[S05](screenshots/S05-puzzle-two.png) + `test_01` |
| 4 | 满 3 枚自动判定 | PASS | [S06](screenshots/S06-puzzle-wrong1.png) + `test_02` |
| 5 | 第 1 次错：次数减 1 + 清空输入 | PASS | S06（余 1 次、右灯灭、三槽清空、红色反馈）+ `test_04` |
| 6 | 第 2 次错：直接失败，无第 3 次 | PASS | [S08](screenshots/S08-ending-failure.png) + `test_05` |
| 7 | 成功结局文案 + 重开可用 | PASS | [S07](screenshots/S07-ending-success.png) |
| 8 | 失败结局文案 + 重开可用 | PASS | S08（且无番外入口，符合设计） |
| 9 | 重开后全部字段复位 | PASS | [S09](screenshots/S09-ending-restart.png) + 3 轮自动复位 |
| 10 | 结算后连点无效 | PASS | 结算后连按 5 次，state 完全不变 |
| 11 | 中文正常显示（非方块） | PASS | [S00](screenshots/S00-font-check.png) 及全部截图 |
| 12 | 新开编辑器可直接打开运行 | PASS | 无缓存副本的完整导入 0 错误；**且导出产物实机启动退出码 0**（见下两节） |

---

## 第 12 项：全新环境导入验证

光在编辑器里点过不算"能打开"——缓存会掩盖很多问题。所以做了一次**无缓存环境**验证：

```bash
# 复制工程，排除 .godot（即排除所有导入缓存与类名注册表）
rsync -a --exclude '.godot' --exclude '.downloads' --exclude 'build' \
      --exclude '.git' --exclude 'deliverables' ./ /tmp/fresh/

# 让 Godot 从这个空缓存目录完整走一遍导入
Godot --headless --editor --quit --path /tmp/fresh
```

结果：

```
ERROR / SCRIPT ERROR / Parse Error / Failed：0 条
.godot/imported/          10 个资源全部导入
global_script_class_cache.cfg  73 个类名注册
```

即：**把一个只有源文件的工程丢给一台干净机器，Godot 能自己把一切建起来并成功加载。**

---

## 导出产物验证

导出不是"命令返回 0"就算完，产物必须真的能启动。

```
导出：tools/export.sh → build/macos/ZhengHeFantasy.zip（57 MB）
解压：郑和：Fantasy.app
启动：./Contents/MacOS/郑和：Fantasy --quit-after 180
结果：退出码 0，无脚本错误、无 autoload 错误、无资源缺失
```

唯一一条报错是 `Failed to open 'user://logs/...'` —— 沙箱不允许写用户日志目录，
与游戏本身无关，本地正常环境下不会出现。

### 包内容核对

| 应存在 | 命中 | 应不存在 | 命中 |
| --- | --- | --- | --- |
| `rune_puzzle` | 7 | `DEVLOG` | 0 |
| `game_state` | 4 | `game_helper`（插件运行时） | 0 |
| `main_theme` | 6 | `make_audio`（工具脚本） | 0 |
| | | `验收记录`（证据文档） | 0 |

> 包里唯一一处 `addons/godot_ai` 字符串，是项目设置 `editor_plugins/enabled` 的历史值。
> 导出包不加载编辑器插件，**零运行时影响**。

### 导出流程里两个必须处理的坑

1. **`_mcp_game_helper` autoload** 指向被排除的 `addons/`，不摘掉的话导出包一启动就报
   "autoload 脚本不存在"。`tools/export.sh` 用 `trap` 保证无论成败都还原 `project.godot`。
2. **ETC2/ASTC 纹理格式未启用** 时，`universal` 架构直接导不出来。
   已在项目设置里打开 `rendering/textures/vram_compression/import_etc2_astc`。

---

## 番外（第二阶段）截图

| # | 状态 | 截图 | 要点 |
| --- | --- | --- | --- |
| S10 | 番外对话 | [S10](screenshots/S10-epilogue-dialogue.png) | 一句一屏，「继续 / 跳过」可用 |
| S11 | 反向谜题 | [S11](screenshots/S11-epilogue-puzzle.png) | 「不限次数」、无灯、无提示、色调偏暖 |
| S12 | 第三结局 | [S12](screenshots/S12-ending-third.png) | 「交　灯」、无番外入口 |

### S13 / S14：为什么不用截图

计划里原本还有两个截图点，最后改成**状态断言**，因为截图在这里是更弱的证据：

| 原计划 | 截图能证明什么 | 改用断言 | 为什么更强 |
| --- | --- | --- | --- |
| S13 连做 3 轮后与 S01 一致 | 两张图像素相同 | 每轮后比对 `state` 全字段 | 光柱是持续扫动的动画，像素永远不会完全相同；比状态才比得出"真的复位了" |
| S14 结算后连点，画面不变 | 看起来没变 | 连点 5 次后比对 `state` | 画面可能因为动画有细微差异，`state` 不变才是幂等的定义 |

结果：`resets_ok = true`、`failure_stable = true`，两项均通过。

---

## 程序化断言（比截图更硬）

在运行中的游戏里直接读字段：

```
A 路径：hint_enabled = true
B 路径：hint_visible = false，hint_text = ""        ← 文本一起清掉，不只是隐藏
第 1 次错：attempts_left = 1，input = []            ← 次数与清空同时成立
重新开始：phase=STORY, hint=false, input=[], attempts=2, outcome=NONE, settled=false
3 轮复位：resets_ok = true                          ← 每次都回到与基线一致的 state
结算幂等：failure_stable = true                     ← 失败后连按 5 次，state 不变
番外：unlimited_attempts = true，连错 5 次仍可继续（test_11）
```

> 注：S01 与 S09 不再逐像素相同，因为光柱是持续扫动的动画。
> 复位正确性改由 `resets_ok` 的状态比对来证明，这比哈希更准。

---

## 本轮发现并修掉的 8 个真实缺陷

| # | 缺陷 | 现象 | 根因 | 修法 |
| --- | --- | --- | --- | --- |
| 1 | **单测假绿** | 变异后测试仍全绿 | 直接改磁盘绕过编辑器缓存，`test_run` 用了旧代码 | 改脚本后必须 `scan`；详见 [ai-log/001](../ai-log/001-测试假绿.md) |
| 2 | **符文完全没画出来** | 三个符文按钮只有文字 | `draw_progress` 初值为 0，切片函数在 t=0 时返回空 | 初值改 1.0，点击时再从 0 补间 |
| 3 | **主场景跑不起来** | 启动即停，无报错 | 直接改 `project.godot` 编辑器不热加载，`run/main_scene` 为空 | 改用 `project_manage` 正式接口写入 |
| 4 | **截图被当资源导入** | `res://docs/` 下 png 全被 Godot 收走 | 证据目录在 `res://` 内 | 加 `docs/.gdignore` |
| 5 | **`AudioManager` 编译失败** | 4 个脚本 `Identifier not found` | 运行中新增 autoload，全局名不进编译期 | 加 `Sfx` 代理层走运行时查找 |
| 6 | **光柱是硬边多边形** | 光束中段出现矩形色块 | 多层楔形叠加，每层末端留一条直边 | 改为沿光束切 14 段、逐段衰减 |
| 7 | **灯塔被面板压住** | 塔身只露半个角 | 灯塔 x=0.80 落在面板范围内 | 剧情面板改左对齐，灯塔移到 x=0.875 |
| 8 | **自己改布局把界面搞塌了** | 标题/正文全消失，提示条变成 475px 高的竖条 | 给提示面板加 `SHRINK_CENTER` 后宽度塌成窄条，里面的自动换行富文本于是竖排 | 补 `custom_minimum_size.x = 560`；**并且是截图当场发现的，单测毫无反应** |

> 第 8 条值得单独看一眼：这是一次**我自己引入**的回归，而且发生在"只是想把提示条收窄一点"这种看起来毫无风险的改动上。
> 它再次印证了那条结论 —— 逻辑测试对布局一无所知，**改界面就必须看图**。

---

## 已知问题 / 待办

| 问题 | 影响 | 计划 |
| --- | --- | --- |
| 结局预设走调试桥时会跳过 `celebrate()` | S07 的灯塔不是最亮状态（实际游玩时会亮） | 可接受；M5 补一张实机成功截图 |
| Export Templates 未安装 | 无法导出可执行包 | 需在编辑器内一次性下载安装 |
| 夜海场景没有真实水面反射 | 只有几何倒影，够用但不惊艳 | 不在范围内，放弃 |

---

## 怎么复现这套验收

```
1. filesystem_manage(scan)             # 确保编辑器拿到最新代码
2. test_run()                          # 12 条不变量
3. project_run(mode="main")
4. game_eval: DebugBridge.goto("<preset>")
5. editor_screenshot(source="game")    # 逐张对照本表
```

预设：`story_initial` / `story_choice_a` / `story_choice_b` / `puzzle_one` /
`puzzle_two` / `puzzle_wrong_1` / `ending_success` / `ending_failure` /
`ending_restart` / `epilogue_dialogue` / `epilogue_puzzle` / `ending_third`
