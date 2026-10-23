class_name NarrativeLibrary
extends RefCounted

## 全部叙事文案的唯一来源。改文案只改这里，不碰场景与逻辑。
##
## 正文用 BBCode（RichTextLabel 渲染）：[i] 斜体用于守塔人的话，
## [color=#...] 用于弱化旁白。

const STORY_TITLE := "灯　塔"

const STORY_BODY := """第七日，雾没有散。

宝船的帆垂着，像一排认命的旗。桅顶的灯照出三尺内的白，三尺之外，什么都没有。

——只有一处光，在你左舷之外。一明，一灭。

守塔人站在塔门下，手里那盏灯，比塔顶的还要暗。

[i]「灯要亮，得先让塔里的三枚符文归位。这机关认的不是力气，是道理。」[/i]

他抬眼看你：[i]「船过重洋，靠的是什么？想起来了，门就开了。」[/i]"""

const CHOICE_HINT := "请教守塔人"
const CHOICE_SELF := "我自己想"

## 选 B 时守塔人补的一句，让不求助也体面
const CHOICE_SELF_REPLY := "[i]「也好。道理是别人的，路是自己的。」[/i]"

const ENDING_SUCCESS_TITLE := "光　路"

const ENDING_SUCCESS_BODY := """光从塔顶立起来，像一根竖着的桅。

雾从中间裂开一条缝，缝里有星。

船队的帆，一面，一面，鼓起来了。"""

const ENDING_SUCCESS_SUMMARY := "航标已点亮 · 船队找到了航路"

const ENDING_FAILURE_TITLE := "停　泊"

const ENDING_FAILURE_BODY := """最后一枚符文落下，机关没有回应。

塔顶的光低下去，低到只剩一点红。

[i]守塔人说：不急。海等得起，明晚再来。[/i]"""

const ENDING_FAILURE_SUMMARY := "灯塔沉寂 · 船队决定暂时停泊"

## 成功结局下方的番外钩子
const EXTRA_PROMPT := "船可以走了。不过在走之前 —— 老朽想问你一句。"
const EXTRA_LABEL := "番外 · 听守塔人讲完 ›"

const ENDING_THIRD_TITLE := "交　灯"

const ENDING_THIRD_BODY := """守塔人听完，很久没有说话。

他把手里的灯，放在塔门的台阶上。

[i]「四十年了。老朽一直以为是海不肯放过他们。」[/i]

[i]「原来是我算错了那一夜。」[/i]

灯没有灭。它只是不再需要有人守着了。"""

const ENDING_THIRD_SUMMARY := "灯塔长明 · 守塔人离开了他的塔"


## —— 番外对话（M4 使用）——

const EPILOGUE_LINES := [
	"[i]「船可以走了。」[/i]",
	"[i]「可老朽想知道 —— 你为什么是这个次序？」[/i]",
	"星定方位，潮定进出，风给船力气。",
	"[i]「……三十年前，有人也是这么说的。」[/i]",
	"[i]「那晚是落潮。出港的窗口只有一刻。」[/i]",
	"[i]「他先算了方位。等他算准，潮已经退了。」[/i]",
	"[i]「船卡在礁口。再也没有回来。」[/i]",
	"[i]「你要是能想明白他错在哪 —— 把这个次序，替老朽走一遍。」[/i]",
]
