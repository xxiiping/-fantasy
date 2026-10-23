class_name InkBackdrop
extends Control

## 水墨背景层：宣纸 + 墨雾。
## 所有场景共用这一层，之后的场景内容挂在它上面。

const PAPER_SHADER := preload("res://shaders/paper.gdshader")
const FOG_SHADER := preload("res://shaders/ink_fog.gdshader")

var _paper: ColorRect
var _fog: ColorRect
var paper_material: ShaderMaterial
var fog_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	_paper = ColorRect.new()
	_paper.name = "Paper"
	_paper.color = Color.WHITE
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_material = ShaderMaterial.new()
	paper_material.shader = PAPER_SHADER
	_paper.material = paper_material
	add_child(_paper)
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_fog = ColorRect.new()
	_fog.name = "InkFog"
	_fog.color = Color.WHITE
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_material = ShaderMaterial.new()
	fog_material.shader = FOG_SHADER
	# 必须显式初始化每个会被 Tween 的 uniform。
	# ShaderMaterial 只有被 set_shader_parameter 过的参数才会出现在属性表里，
	# 否则 Tween 会报 "property does not exist"。
	fog_material.set_shader_parameter("density", 0.75)
	fog_material.set_shader_parameter("edge_pull", 0.0)
	_fog.material = fog_material
	add_child(_fog)
	_fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## 雾的浓度，0 = 清朗，1.4 = 浓得化不开
func set_fog_density(value: float, duration := 1.0) -> void:
	if duration <= 0.0:
		fog_material.set_shader_parameter("density", value)
		return
	var tween := create_tween()
	tween.tween_property(fog_material, "shader_parameter/density", value, duration)


## 判错时雾从四边压进来
func pulse_ink(strength := 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(fog_material, "shader_parameter/edge_pull", strength, 0.45)
	tween.tween_property(fog_material, "shader_parameter/edge_pull", 0.0, 1.2)


## 退雾：雾变薄、四边松开
func clear_fog(duration := 2.0) -> void:
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(fog_material, "shader_parameter/density", 0.18, duration)
	tween.tween_property(fog_material, "shader_parameter/edge_pull", 0.0, duration)
