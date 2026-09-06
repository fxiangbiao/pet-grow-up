extends Control
class_name PetBubble
##
## PetBubble — 宠物台词气泡（一次性 overlay）
## UiKit.pet_say 在各场景调用；气泡出现在宠物上方，圆角卡片+弹出动画+自动消失。

static func say(parent: Control, anchor: Vector2, text: String, dur: float = 2.8, width: float = 380.0) -> void:
	if parent == null or text == "" or not parent.is_inside_tree():
		return
	var b := PetBubble.new()
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	b._start(anchor, text, dur, width)


func _start(anchor: Vector2, text: String, dur: float, width: float) -> void:
	var avail := maxf(220.0, parent_area_width() - 28.0)
	width = minf(width, avail)
	var style := UiKit.card(18, Color(1, 1, 1, 0.97), Color(0.95, 0.72, 0.25, 0.9), 2)
	style.shadow_color = Color(0.1, 0.2, 0.25, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(width, 0)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", UiKit.INK)
	panel.add_child(label)
	add_child(panel)

	# 气泡放到宠物上方（anchor 为宠物位置）
	var pw := parent_area_width()
	var px := clampf(anchor.x - width + 60.0, 14.0, maxf(14.0, pw - width - 14.0))
	var py := clampf(anchor.y - 120.0, 12.0, maxf(12.0, anchor.y - 220.0))
	panel.position = Vector2(px, py)

	# 弹出 + 停留 + 淡出
	panel.pivot_offset = Vector2(width / 2.0, 20)
	panel.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(maxf(dur - 0.5, 0.4))
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


func parent_area_width() -> float:
	var p := get_parent()
	if p is Control and p.size.x > 0:
		return p.size.x
	var vp := get_viewport()
	if vp != null:
		return vp.size.x
	return 900.0
