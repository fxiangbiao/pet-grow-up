extends Control
##
## ActBase — 教/学/练/拓 四幕的通用基类
## 子类实现 _build() 构建自己的界面；完成后调用 emit_signal("finished") 进入下一幕。

signal finished

var ctx: Dictionary = {}
var pet: Node2D
var _scroll: VBoxContainer
var _fs: float = 1.0


func _update_font_scale() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var h := float(vp.size.y)
	_fs = clampf(h / 600.0, 1.0, 1.5)


## 当前字体缩放系数（基于视口高度 / 600，上限 1.5）
func _font_scale() -> float:
	return _fs


func font_size(base: int) -> int:
	return int(float(base) * _fs)


func setup(c: Dictionary) -> void:
	ctx = c
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_font_scale()
	_spawn_pet()
	_build_scroll()
	_build()


func _spawn_pet() -> void:
	if pet == null:
		pet = PetController.spawn(Vector2.ZERO)
		pet.z_index = 100
		add_child(pet)
	_update_pet_position()
	if not resized.is_connected(_update_pet_position):
		resized.connect(_update_pet_position)


func _update_pet_position() -> void:
	var sz := self.size
	if sz.x <= 0 or sz.y <= 0:
		return
	# 放在右下角，留一点边距，避免被窗口边缘裁剪
	pet.position = Vector2(sz.x - 110, sz.y - 130)


func _build_scroll() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 24
	margin.offset_top = 12
	margin.offset_right = -170  # 给右下角宠物留空间
	margin.offset_bottom = -16
	add_child(margin)

	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(sc)

	_scroll = VBoxContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_theme_constant_override("separation", 16)
	_scroll.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	sc.add_child(_scroll)


## 便捷：加一个标题
func add_heading(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size(22))
	l.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_scroll.add_child(l)


## 便捷：加一段正文，支持顶部额外间距
func add_paragraph(text: String, extra_top_margin: int = 0) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	l.add_theme_font_size_override("font_size", font_size(16))
	l.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	if extra_top_margin > 0:
		l.add_theme_constant_override("margin_top", extra_top_margin)
	_scroll.add_child(l)


## 子类重写
func _build() -> void:
	pass


func _is_offline() -> bool:
	return ApiClient.token == "" or int(ctx.get("node_id", -1)) <= 0


## 转发到 learning_loop 的 toast（learning_loop 继承 base_scene 拥有 toast）
func toast(msg: String) -> void:
	var root = get_tree().current_scene
	if root != null and root.has_method("toast"):
		root.toast(msg)


## 从 "8 + 5 = ?" 这类文本解析出 [a, b]
func _parse_add(text: String) -> Array:
	var s := text.replace(" ", "").replace("=?", "").replace("=", "")
	var parts := s.split("+")
	if parts.size() >= 2:
		return [int(parts[0]), int(parts[1])]
	return [0, 0]
