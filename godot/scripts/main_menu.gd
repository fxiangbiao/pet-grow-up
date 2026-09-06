extends Control
##
## 主菜单：登录（真实后端）或离线试玩

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
	# 启动后将窗口设为「屏幕一半大小」：宽 = 屏宽一半，高 ≈ 屏高（留任务栏边距），并居中。
	# 用运行时动态读取屏幕分辨率，换电脑也自适应；最小值不低于原 960x600 设计基准。
	# 注：Godot 4.7 的 DisplayServer 无 FEATURE_WINDOW 枚举成员，桌面端直接调用窗口 API 即可。
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
	# 标题
	var scale := _font_scale()
	var title := Label.new()
	title.text = "Pet Grow Up"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(42 * scale))
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 90
	title.offset_bottom = 150
	add_child(title)


func _build_ui() -> void:
	var scale := _font_scale()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(12 * scale))
	center.add_child(box)

	_user = LineEdit.new()
	_user.placeholder_text = "用户名"
	_user.add_theme_font_size_override("font_size", int(18 * scale))
	_user.custom_minimum_size = Vector2(280, 38) * scale
	box.add_child(_user)

	_pwd = LineEdit.new()
	_pwd.placeholder_text = "密码"
	_pwd.secret = true
	_pwd.add_theme_font_size_override("font_size", int(18 * scale))
	_pwd.custom_minimum_size = Vector2(280, 38) * scale
	box.add_child(_pwd)

	var login := Button.new()
	login.text = "登录"
	login.add_theme_font_size_override("font_size", int(20 * scale))
	login.custom_minimum_size = Vector2(280, 42) * scale
	login.pressed.connect(_on_login)
	box.add_child(login)

	var offline := Button.new()
	offline.text = "离线试玩（无需后端）"
	offline.add_theme_font_size_override("font_size", int(18 * scale))
	offline.custom_minimum_size = Vector2(280, 36) * scale
	offline.pressed.connect(_on_offline)
	box.add_child(offline)

	var hint := Label.new()
	hint.text = "提示：需先启动后端 pet-grow-up（默认 http://127.0.0.1:8080）。"
	hint.add_theme_font_size_override("font_size", int(14 * scale))
	hint.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(320, 0) * scale
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
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")


func _on_login_ok() -> void:
	if _switching:
		return
	_switching = true
	PetState.load_state()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")


func _on_login_fail(msg: String) -> void:
	_toast("登录失败：" + msg)


func _on_req_fail(msg: String) -> void:
	_toast(msg)


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
