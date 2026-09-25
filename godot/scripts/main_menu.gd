extends Control
##
## 主菜单：登录（真实后端）/ 离线试玩 / 设置
## 统一使用 UiKit 圆角卡片风格；登录取消/进入均有淡转场。

var _user: LineEdit
var _pwd: LineEdit
var _switching := false


func _ready() -> void:
	_resize_to_half_screen()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_bg()
	_build_ui()
	ApiClient.login_succeeded.connect(_on_login_ok)
	ApiClient.login_failed.connect(_on_login_fail)
	ApiClient.request_failed.connect(_on_req_fail)


func _resize_to_half_screen() -> void:
	var screen: Vector2i = DisplayServer.screen_get_size()
	var w: int = int(float(screen.x) * 0.5)
	var h: int = int(float(screen.y) * 0.94)
	w = maxi(w, 720)
	h = maxi(h, 540)
	DisplayServer.window_set_size(Vector2i(w, h))
	DisplayServer.window_set_position(Vector2i(int(float(screen.x - w) / 2), int(float(screen.y - h) / 2)))


func _draw_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.82, 0.78)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var scale := _font_scale()
	var title := Label.new()
	title.text = "Pet Grow Up"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(44 * scale))
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_color_override("font_outline_color", UiKit.INK)
	title.add_theme_constant_override("outline_size", 10)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 90
	title.offset_bottom = 170
	add_child(title)


func _build_ui() -> void:
	var scale := _font_scale()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	var style := UiKit.card(24, Color(1, 1, 1, 0.92), Color(1, 1, 1, 0.55), 0)
	style.shadow_color = Color(0.1, 0.3, 0.35, 0.25)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 34
	style.content_margin_bottom = 30
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(14 * scale))
	card.add_child(box)

	_user = LineEdit.new()
	_user.placeholder_text = "用户名"
	_user.add_theme_font_size_override("font_size", int(18 * scale))
	_user.custom_minimum_size = Vector2(320, 48) * scale
	box.add_child(_user)

	_pwd = LineEdit.new()
	_pwd.placeholder_text = "密码"
	_pwd.secret = true
	_pwd.add_theme_font_size_override("font_size", int(18 * scale))
	_pwd.custom_minimum_size = Vector2(320, 48) * scale
	box.add_child(_pwd)

	var login := Button.new()
	login.text = "登录"
	login.custom_minimum_size = Vector2(320, 52) * scale
	login.pressed.connect(_on_login)
	UiKit.style_button(login, true, 14, int(20 * scale))
	box.add_child(login)

	var offline := Button.new()
	offline.text = "离线试玩（无需后端）"
	offline.custom_minimum_size = Vector2(320, 52) * scale
	offline.pressed.connect(_on_offline)
	UiKit.style_button(offline, false, 14, int(18 * scale))
	box.add_child(offline)

	var settings := Button.new()
	settings.text = "⚙ 设置（音量 / 震动 / 气泡）"
	settings.custom_minimum_size = Vector2(320, 48) * scale
	settings.pressed.connect(_open_settings)
	UiKit.style_button(settings, false, 14, int(16 * scale))
	box.add_child(settings)

	var hint := Label.new()
	hint.text = "提示：需先启动后端 pet-grow-up（默认 http://127.0.0.1:8080）。"
	hint.add_theme_font_size_override("font_size", int(13 * scale))
	hint.add_theme_color_override("font_color", UiKit.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(340, 0)
	box.add_child(hint)


func _font_scale() -> float:
	var h := float(get_viewport().size.y)
	return clampf(h / 600.0, 1.0, 1.5)


func _on_login() -> void:
	var u := _user.text.strip_edges()
	var p := _pwd.text
	if u == "":
		_toast("请输入用户名")
		return
	ApiClient.login(u, p)


func _on_offline() -> void:
	if _switching:
		return
	_switching = true
	ApiClient.logout()
	PetState.load_state()
	UiKit.change_scene(get_tree(), "res://scenes/world_map.tscn")


func _on_login_ok() -> void:
	if _switching:
		return
	_switching = true
	PetState.load_state()
	UiKit.change_scene(get_tree(), "res://scenes/world_map.tscn")


func _on_login_fail(msg: String) -> void:
	_switching = false
	_toast("登录失败：" + msg)


func _on_req_fail(msg: String) -> void:
	_toast(msg)


# ===================== 设置面板 =====================

func _open_settings() -> void:
	if get_node_or_null("SettingsModal") != null:
		return
	var overlay := CenterContainer.new()
	overlay.name = "SettingsModal"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.12, 0.14, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	var style := UiKit.card(22, Color(1, 1, 1, 0.98), Color(0.6, 0.85, 0.9), 2)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(440, 0)
	panel.add_child(box)

	var title := Label.new()
	title.text = "⚙ 设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiKit.INK)
	box.add_child(title)

	box.add_child(_slider_row("🔊 主音量", Settings.master_volume, _on_master_changed))
	box.add_child(_slider_row("🎵 音效音量", Settings.sfx_volume, _on_sfx_changed))

	var shake := CheckButton.new()
	shake.text = "💥 屏幕震动反馈"
	shake.button_pressed = Settings.shake_enabled
	shake.toggled.connect(_on_shake_toggled)
	box.add_child(shake)

	var bubble := CheckButton.new()
	bubble.text = "💬 宠物台词气泡"
	bubble.button_pressed = Settings.bubble_enabled
	bubble.toggled.connect(_on_bubble_toggled)
	box.add_child(bubble)

	var close := Button.new()
	close.text = "完成"
	close.custom_minimum_size = Vector2(240, 48)
	close.pressed.connect(func(): overlay.queue_free())
	UiKit.style_button(close, true, 14, 18)
	var wrap := CenterContainer.new()
	wrap.add_child(close)
	box.add_child(wrap)


func _slider_row(label: String, value: float, cb: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lab := Label.new()
	lab.text = label
	lab.add_theme_font_size_override("font_size", 17)
	lab.add_theme_color_override("font_color", UiKit.INK)
	row.add_child(lab)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = clampf(value, 0.0, 1.0) * 100.0
	slider.custom_minimum_size = Vector2(360, 40)
	slider.value_changed.connect(func(v: float): cb.call(v / 100.0))
	row.add_child(slider)
	return row


func _on_master_changed(v: float) -> void:
	Settings.set_master(v)


func _on_sfx_changed(v: float) -> void:
	Settings.set_sfx(v)


func _on_shake_toggled(on: bool) -> void:
	Settings.set_shake(on)


func _on_bubble_toggled(on: bool) -> void:
	Settings.set_bubble(on)


func _toast(msg: String) -> void:
	var scale := _font_scale()
	var t := Label.new()
	t.text = msg
	t.add_theme_font_size_override("font_size", int(16 * scale))
	t.add_theme_color_override("font_color", Color(1, 0.9, 0.9))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	t.offset_top = -60 * scale
	t.offset_bottom = -30 * scale
	add_child(t)
	await get_tree().create_timer(2.0).timeout
	t.queue_free()
