class_name BackdropView
extends Control

## 背景层：天空 / 雾 / 灯塔 / 星屑，全部程序化在代码里搭起来。
##
## 为什么用代码而不是 .tscn：这些视觉全是 shader + 自绘 + 粒子参数，
## 在检查器里调不出内容；写成代码反而更可读，也少一处 .tscn 出错的地方。

const SKY_SHADER := preload("res://shaders/sky.gdshader")
const FOG_SHADER := preload("res://shaders/fog.gdshader")
const LighthouseScript := preload("res://scripts/ui/lighthouse.gd")

const BASE_FOG_DENSITY := 0.85
const BASE_GLOW := 0.35

var _shake: Control
var _sky: ColorRect
var _fog: ColorRect
var _lighthouse: Lighthouse

var _sky_material: ShaderMaterial
var _fog_material: ShaderMaterial
var _burst: CPUParticles2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	resized.connect(_on_resized)


# ---------------------------------------------------------------- 搭建

func _build() -> void:
	_shake = _make_full_rect_control("Shake")
	add_child(_shake)
	_full_rect(_shake)

	_sky = ColorRect.new()
	_sky.name = "Sky"
	_sky.color = Color.WHITE
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = SKY_SHADER
	_sky_material.set_shader_parameter("glow_strength", BASE_GLOW)
	_sky.material = _sky_material
	_shake.add_child(_sky)
	_full_rect(_sky)

	_fog = ColorRect.new()
	_fog.name = "Fog"
	_fog.color = Color.WHITE
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = FOG_SHADER
	_fog_material.set_shader_parameter("density", BASE_FOG_DENSITY)
	_fog.material = _fog_material
	_shake.add_child(_fog)
	_full_rect(_fog)

	_lighthouse = LighthouseScript.new()
	_lighthouse.name = "Lighthouse"
	_shake.add_child(_lighthouse)
	_full_rect(_lighthouse)

	_burst = _build_burst()
	add_child(_burst)
	_on_resized()


func _build_burst() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "StarBurst"
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 70
	particles.lifetime = 2.6
	particles.explosiveness = 0.9
	particles.texture = _make_star_texture()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(250.0, 24.0)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 42.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 175.0
	particles.gravity = Vector2(0.0, -26.0)
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 1.4
	particles.color = Color(1.0, 0.92, 0.70, 1.0)
	return particles


## 星屑用径向渐变生成，避免引入任何图片文件
func _make_star_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.95, 0.78, 1.0))
	gradient.set_color(1, Color(1.0, 0.82, 0.45, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


# ---------------------------------------------------------------- 对外

## 判错：灯变暗、雾变浓并向边缘收拢、轻微震屏
func pulse_wrong() -> void:
	_lighthouse.energy = 0.55
	var fog_tween := create_tween()
	fog_tween.tween_property(
		_fog_material,
		"shader_parameter/density",
		minf(_current_fog() + 0.30, 1.7),
		0.5
	)
	var edge_tween := create_tween()
	edge_tween.tween_property(_fog_material, "shader_parameter/edge_pull", 0.55, 0.5)
	_shake_screen()


## 成功：光柱骤亮、雾散、星屑上浮、天空提亮
func celebrate() -> void:
	_lighthouse.energy = 2.2

	_burst.emitting = false
	_burst.emitting = true

	var fog_tween := create_tween()
	fog_tween.tween_property(_fog_material, "shader_parameter/density", 0.26, 1.4)
	var edge_tween := create_tween()
	edge_tween.tween_property(_fog_material, "shader_parameter/edge_pull", 0.0, 1.0)
	var sky_tween := create_tween()
	sky_tween.tween_property(_sky_material, "shader_parameter/glow_strength", 0.95, 1.2)


## 重新开始：一切回到开场
func reset_visuals() -> void:
	_lighthouse.energy = 1.0
	_fog_material.set_shader_parameter("density", BASE_FOG_DENSITY)
	_fog_material.set_shader_parameter("edge_pull", 0.0)
	_sky_material.set_shader_parameter("glow_strength", BASE_GLOW)
	_burst.emitting = false
	_shake.position = Vector2.ZERO


# ---------------------------------------------------------------- 内部

func _current_fog() -> float:
	return float(_fog_material.get_shader_parameter("density"))


func _shake_screen() -> void:
	var tween := create_tween()
	for i in 4:
		var offset := Vector2(randf_range(-7.0, 7.0), randf_range(-4.0, 4.0))
		tween.tween_property(_shake, "position", offset, 0.04)
	tween.tween_property(_shake, "position", Vector2.ZERO, 0.10)


func _on_resized() -> void:
	if _burst != null:
		_burst.position = Vector2(size.x * 0.875, size.y * 0.64 - 150.0)


func _make_full_rect_control(node_name: String) -> Control:
	var node := Control.new()
	node.name = node_name
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _full_rect(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
