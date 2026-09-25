extends Node
class_name UiKit
##
## UiKit — 轻量 UI 工具箱（调色板 / 卡片与按钮样式 / 场景淡转场）
## 用 class_name 暴露，无需注册 autoload。各场景需要时直接调用。

## —— 调色板（全端统一）——
const INK := Color(0.15, 0.35, 0.4)          # 主文字（深青）
const INK_SOFT := Color(0.25, 0.45, 0.5)     # 次要文字
const SKY := Color(0.55, 0.82, 0.78)         # 主题蓝绿
const TEAL := Color(0.2, 0.55, 0.55)         # 强调深青
const AMBER := Color(0.94, 0.62, 0.15)       # 关卡/奖励橙
const GREEN := Color(0.36, 0.79, 0.65)       # 完成绿
const CARD_BG := Color(1, 1, 1, 0.94)        # 卡片底
const BORDER := Color(0.6, 0.85, 0.9)        # 卡片描边


## 通用卡片 StyleBoxFlat
static func card(radius: int = 16, bg: Color = CARD_BG, border: Color = BORDER, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = bw
	s.border_width_top = bw
	s.border_width_right = bw
	s.border_width_bottom = bw
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


## 让按钮统一成圆角卡片风格；accent=true 用主题色底
static func style_button(btn: Button, accent: bool = false, radius: int = 12, font_size: int = 0) -> void:
	var base := Color(1, 1, 1, 0.95) if not accent else TEAL
	var text_c := INK if not accent else Color(1, 1, 1)
	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = BORDER if not accent else Color(1, 1, 1, 0.35)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_left = radius
	normal.corner_radius_bottom_right = radius
	normal.shadow_color = Color(0.1, 0.3, 0.35, 0.18)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 2)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate()
	hover.bg_color = (Color(1.0, 0.98, 0.85) if not accent else TEAL.lightened(0.12))
	hover.shadow_size = 10
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.9, 0.93, 0.94, 0.8)
	disabled.border_color = Color(0.8, 0.84, 0.85)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", text_c)
	btn.add_theme_color_override("font_hover_color", text_c)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.62, 0.64))
	if font_size > 0:
		btn.add_theme_font_size_override("font_size", font_size)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## 触屏/点按最小热区补齐（不够 48px 则放大）
static func touch_size(btn: Control, min_px: int = 48) -> void:
	var s := btn.custom_minimum_size
	if s.y < min_px:
		btn.custom_minimum_size = Vector2(maxf(s.x, 96), float(min_px))


## —— 场景淡转场：fade-out → change_scene → fade-in ——
static func change_scene(tree: SceneTree, path: String) -> void:
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	tree.root.add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0.04, 0.08, 0.09, 1)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	rect.modulate.a = 0.0
	var tween := layer.create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.18)
	await tween.finished
	tree.change_scene_to_file(path)
	await tree.process_frame
	await tree.process_frame
	var tween2 := layer.create_tween()
	tween2.tween_property(rect, "modulate:a", 0.0, 0.24)
	await tween2.finished
	layer.queue_free()
