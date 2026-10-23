class_name RuneDefinition
extends Resource

## 一枚符文的定义。纯数据，不含任何逻辑。
## 三份实例：星象 / 海潮 / 季风。

## 字形种类，决定 _draw() 走哪条绘制分支
enum Glyph { STAR, TIDE, WIND }

@export var id: StringName = &""
@export var display_name: String = ""
@export var glyph: Glyph = Glyph.STAR
@export var tint: Color = Color.WHITE
## 决定程序化笔画的抖动，同一个种子每次画出来一致
@export var stroke_seed: int = 0
