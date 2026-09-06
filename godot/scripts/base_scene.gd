extends Control
##
## BaseScene — 所有界面的通用底座
## 提供：全屏背景、顶栏(返回/标题/能量)、右下角宠物、toast 提示。
## 子类在 _on_setup() 中写自己的内容，并把控件加进 content。

var pet: Node2D
var content: MarginContainer
var back_scene_path := "res://scenes/main_menu.tscn"
var show_back := true

var _title_label: Label
var _energy_label: Label
var _level_label: Label
var _exp_bar: ProgressBar


func _ready() -> void:
	layout_mode = 1  # LAYOUT_MODE_ANCHORS：避免默认 UNCONTROLLED 下预设 anchors 不生效
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_key_input(true)
	_draw_background()
	_build_top_bar()
	_build_content()
	_on_setup()          # 优先构建子类内容，确保界面不被后续步骤（如宠物实例化）阻断
	_place_pet()         # 宠物放最后；即便 spawn 出错也不影响内容显示
	refresh_energy()


## Esc 返回上一页（若当前有输入控件持有焦点则不拦截，避免误伤正在输入的文本）
func _unhandled_key_input(event: InputEvent) -> void:
	if not show_back:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner is LineEdit or focus_owner is TextEdit:
				return
			if not get_tree().current_scene == self:
				return
			_on_back()


func _on_login_ok() -> void:
	pass


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.92, 0.97, 0.98)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_top_bar() -> void:
	var bar := Control.new()
	bar.name = "TopBar"
	bar.anchor_left = 0.0; bar.anchor_top = 0.0; bar.anchor_right = 1.0; bar.anchor_bottom = 0.0
	bar.offset_left = 0; bar.offset_top = 0; bar.offset_right = 0; bar.offset_bottom = 56
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var scale := _font_scale()
	if show_back:
		var back := Button.new()
		back.text = "← 返回"
		back.add_theme_font_size_override("font_size", int(15 * scale))
		back.position = Vector2(16, 8)
		back.size = Vector2(104, 44) * scale
		back.pressed.connect(_on_back)
		UiKit.style_button(back, false, 12)
		bar.add_child(back)

	_title_label = Label.new()
	_title_label.text = "Pet Grow Up"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", int(18 * scale))
	_title_label.anchor_left = 0.0; _title_label.anchor_top = 0.0
	_title_label.anchor_right = 1.0; _title_label.anchor_bottom = 0.0
	_title_label.offset_left = 0; _title_label.offset_top = 0
	_title_label.offset_right = 0; _title_label.offset_bottom = 56
	bar.add_child(_title_label)

	# 右侧 HUD：等级 + 经验条 + 能量
	var hud := VBoxContainer.new()
	hud.anchor_left = 1.0; hud.anchor_top = 0.0; hud.anchor_right = 1.0; hud.anchor_bottom = 0.0
	hud.offset_left = -270 * scale; hud.offset_top = 8
	hud.offset_right = -16; hud.offset_bottom = 56
	hud.add_theme_constant_override("separation", 3)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(hud)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	row1.size_flags_horizontal = Control.SIZE_SHRINK_END
	hud.add_child(row1)

	_level_label = Label.new()
	_level_label.text = "Lv 1"
	_level_label.add_theme_font_size_override("font_size", int(15 * scale))
	_level_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	row1.add_child(_level_label)

	_energy_label = Label.new()
	_energy_label.text = "⚡ --"
	_energy_label.add_theme_font_size_override("font_size", int(15 * scale))
	_energy_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	row1.add_child(_energy_label)

	_exp_bar = ProgressBar.new()
	_exp_bar.custom_minimum_size = Vector2(240 * scale, 10 * scale)
	_exp_bar.show_percentage = false
	_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_exp_bar)


func _font_scale() -> float:
	var h := float(get_viewport().size.y)
	return clampf(h / 600.0, 1.0, 1.5)


func _build_content() -> void:
	content = MarginContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = 64
	content.set("theme_override_constants/margin_left", 44)
	content.set("theme_override_constants/margin_right", 44)
	content.set("theme_override_constants/margin_top", 24)
	content.set("theme_override_constants/margin_bottom", 24)
	add_child(content)


func _place_pet() -> void:
	if pet == null:
		var p = PetController.spawn(Vector2.ZERO)
		if is_instance_valid(p):
			pet = p
			add_child(pet)
		else:
			push_warning("PetController.spawn 返回了无效实例，跳过宠物显示")
	_update_pet_position()
	if not resized.is_connected(_update_pet_position):
		resized.connect(_update_pet_position)


func _update_pet_position() -> void:
	if pet == null:
		return
	var sz := self.size
	if sz.x <= 0 or sz.y <= 0:
		return
	pet.position = Vector2(sz.x - 120, sz.y - 150)


func set_title(t: String) -> void:
	if _title_label:
		_title_label.text = t


func refresh_hud() -> void:
	if _energy_label:
		_energy_label.text = "⚡ %d/%d" % [PetState.energy, PetState.max_energy]
	if _level_label:
		_level_label.text = "Lv %d · %s" % [PetState.level, PetState.stage_name()]
	if _exp_bar:
		_exp_bar.max_value = float(PetState.exp_needed(PetState.level))
		_exp_bar.value = float(PetState.exp)


func refresh_energy() -> void:
	refresh_hud()


func _on_back() -> void:
	UiKit.change_scene(get_tree(), back_scene_path)


## 宠物台词气泡：出现在宠物上方；设置里可整体关闭
func pet_say(msg: String, dur: float = 2.8) -> void:
	if msg == "" or not is_inside_tree():
		return
	if not Settings.bubble_enabled:
		return
	var anchor := Vector2(maxf(size.x - 150.0, 0.0), maxf(size.y - 170.0, 0.0))
	if pet is Node2D:
		anchor = pet.position + Vector2(-20, -60)
	PetBubble.say(self, anchor, msg, dur)


func toast(msg: String) -> void:
	var scale := _font_scale()
	var t := Label.new()
	t.text = msg
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	t.offset_left = 0; t.offset_top = -70 * scale; t.offset_right = 0; t.offset_bottom = -30 * scale
	t.add_theme_font_size_override("font_size", int(16 * scale))
	t.add_theme_stylebox_override("normal", _toast_style())
	t.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(t)
	var tw := create_tween()
	tw.tween_property(t, "modulate:a", 0.0, 1.6).set_delay(1.2)
	tw.tween_callback(t.queue_free)


func _toast_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.25, 0.35, 0.9)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	return s


## 子类重写此函数添加自己的内容
func _on_setup() -> void:
	pass
