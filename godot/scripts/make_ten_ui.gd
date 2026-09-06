extends PanelContainer
##
## MakeTenUI — 凑十法交互组件（点苹果凑十）
## 大数已作为红苹果放在十格阵里，孩子点绿苹果：先补齐到 10，再把余下的放进「剩余」区。
## 全部放完后发出 completed(答案字符串)。guided=true 为引导演示（不判分）。

signal completed(answer: String)
signal ten_reached

const TEX_RED := preload("res://assets/sprites/pet/apple_red.png")
const TEX_GREEN := preload("res://assets/sprites/pet/apple_green.png")
const TEX_SLOT := preload("res://assets/sprites/pet/slot_empty.png")

var _big := 8
var _small := 5
var _guided := false

var _slots: Array = []          # 10 个 TextureRect
var _frame_filled := 0          # 已补进十格阵的绿苹果数（不含 _big）
var _rest := 0
var _basket: HBoxContainer
var _rest_box: HBoxContainer
var _status: Label
var _hint: Label
var _defer_build := false        # setup 在入树前调用时，延迟到 _ready 构建


func setup(big: int, small: int, guided: bool) -> void:
	_big = clampi(big, 1, 10)
	_small = maxi(small, 0)
	_guided = guided
	# 必须在进入场景树后构建：_font_scale() 依赖 get_viewport().size，
	# 未入树时 get_viewport() 返回 null 会崩溃。
	if is_inside_tree():
		_build()
	else:
		_defer_build = true


func _ready() -> void:
	if _defer_build:
		_defer_build = false
		_build()


func _build() -> void:
	var scale := _font_scale()
	# 卡片外观
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.75)
	style.border_color = Color(0.6, 0.85, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(460, 0) * scale
	var pad := int(16 * scale)
	add_theme_constant_override("margin_left", pad)
	add_theme_constant_override("margin_top", pad)
	add_theme_constant_override("margin_right", pad)
	add_theme_constant_override("margin_bottom", pad)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", int(12 * scale))
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	# 提示语
	_hint = Label.new()
	_hint.text = "👉 先点绿苹果凑满 10，再把剩下的放进「剩余」"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", int(16 * scale))
	_hint.add_theme_color_override("font_color", Color(0.2, 0.45, 0.55))
	root.add_child(_hint)

	# 十格阵外框
	var frame_box := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.95, 0.99, 1.0)
	frame_style.border_color = Color(0.75, 0.9, 0.95)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.corner_radius_top_left = 10
	frame_style.corner_radius_top_right = 10
	frame_style.corner_radius_bottom_left = 10
	frame_style.corner_radius_bottom_right = 10
	frame_box.add_theme_stylebox_override("panel", frame_style)
	frame_box.add_theme_constant_override("margin_left", 10)
	frame_box.add_theme_constant_override("margin_top", 10)
	frame_box.add_theme_constant_override("margin_right", 10)
	frame_box.add_theme_constant_override("margin_bottom", 10)
	root.add_child(frame_box)

	var frame := HBoxContainer.new()
	frame.add_theme_constant_override("separation", int(6 * scale))
	frame_box.add_child(frame)
	for i in range(10):
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(36, 36) * scale
		slot.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		if i < _big:
			slot.texture = TEX_RED
		else:
			slot.texture = TEX_SLOT
		_slots.append(slot)
		frame.add_child(slot)

	# 篮子 + 剩余 横向并排，节省纵向空间
	var pool_row := HBoxContainer.new()
	pool_row.add_theme_constant_override("separation", int(24 * scale))
	pool_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(pool_row)

	var basket_col := VBoxContainer.new()
	basket_col.add_theme_constant_override("separation", int(6 * scale))
	basket_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_row.add_child(basket_col)

	var basket_label := Label.new()
	basket_label.text = "🧺 篮子里的苹果："
	basket_label.add_theme_font_size_override("font_size", int(16 * scale))
	basket_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	basket_col.add_child(basket_label)

	_basket = HBoxContainer.new()
	_basket.add_theme_constant_override("separation", int(6 * scale))
	basket_col.add_child(_basket)
	for i in range(_small):
		var apple := TextureButton.new()
		apple.texture_normal = TEX_GREEN
		apple.custom_minimum_size = Vector2(36, 36) * scale
		apple.pressed.connect(_on_apple_pressed.bind(apple))
		_basket.add_child(apple)
		# 给第一个绿苹果加脉冲提示，吸引点击
		if i == 0:
			_start_pulse(apple)

	var rest_col := VBoxContainer.new()
	rest_col.add_theme_constant_override("separation", int(6 * scale))
	rest_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_row.add_child(rest_col)

	var rest_label := Label.new()
	rest_label.text = "📦 剩余："
	rest_label.add_theme_font_size_override("font_size", int(16 * scale))
	rest_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	rest_col.add_child(rest_label)

	_rest_box = HBoxContainer.new()
	_rest_box.add_theme_constant_override("separation", int(6 * scale))
	rest_col.add_child(_rest_box)

	_status = Label.new()
	_status.text = "开始吧～"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", int(18 * scale))
	_status.add_theme_color_override("font_color", Color(0.15, 0.45, 0.55))
	root.add_child(_status)


func _font_scale() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	var h := float(vp.size.y)
	return clampf(h / 600.0, 1.0, 1.5)


func _start_pulse(apple: TextureButton) -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(apple, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.5)
	tw.tween_property(apple, "modulate", Color(1, 1, 1, 1.0), 0.5)


func _stop_pulse(apple: TextureButton) -> void:
	apple.modulate = Color(1, 1, 1, 1)


func _on_apple_pressed(apple: TextureButton) -> void:
	_stop_pulse(apple)
	var need := 10 - _big
	if _frame_filled < need:
		var idx := _big + _frame_filled
		_slots[idx].texture = TEX_GREEN
		_frame_filled += 1
		apple.queue_free()
		if _frame_filled == need:
			_status.text = "🎉 凑成 10 啦！把剩下的放进「剩余」"
			_status.add_theme_color_override("font_color", Color(0.9, 0.35, 0.25))
			ten_reached.emit()
			# 给剩余区第一个苹果加脉冲提示（如果有）
			if _basket.get_child_count() > 0:
				_start_pulse(_basket.get_child(0))
	else:
		var r := TextureRect.new()
		r.texture = TEX_GREEN
		r.custom_minimum_size = Vector2(34, 34) * _font_scale()
		_rest_box.add_child(r)
		_rest += 1
		apple.queue_free()
	if _basket.get_child_count() == 0:
		var sum := _big + _small
		_status.text = "✅ 完成！ 10 + %d = %d" % [_rest, sum]
		_status.add_theme_color_override("font_color", Color(0.15, 0.55, 0.3))
		completed.emit(str(sum))
	else:
		# 更新提示
		if _frame_filled < need:
			_hint.text = "继续点绿苹果，把十格阵补满～"
		elif _basket.get_child_count() > 0:
			_hint.text = "十格阵已经满了，把剩下的绿苹果点进「剩余」"
