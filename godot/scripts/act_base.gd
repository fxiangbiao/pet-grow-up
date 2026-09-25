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


## 宠物台词气泡（贴近本幕右下角宠物），设置关闭时跳过
func pet_say(msg: String, dur: float = 2.6) -> void:
	if msg == "" or not is_inside_tree():
		return
	if not Settings.bubble_enabled:
		return
	var anchor := Vector2(maxf(size.x - 120.0, 0.0), maxf(size.y - 140.0, 0.0))
	if pet is Node2D:
		anchor = pet.position + Vector2(-30, -70)
	PetBubble.say(self, anchor, msg, dur)


## 从 "8 + 5 = ?" 这类文本解析出 [a, b]（求和形式，兼容旧调用方）
func _parse_add(text: String) -> Array:
	var p := _parse_question(text)
	return [int(p["big"]), int(p["small"])]


## 统一题型解析：
##   sum        — "A + B = ?"：十格阵摆 A，篮子里放 B 个苹果；先补满十，
##                余下的点进「剩余」，答案 = A + B（离线演示/教学卡）
##   complement — "凑十法：A + ? = 10"：十格阵摆 A 个红苹果，篮子里放
##                (10-A) 个绿苹果；点满十格阵即答对，答案 = 10-A
##                （后端 SCENE_DRAG 按缺加数判分）
func _parse_question(text: String) -> Dictionary:
	var s := text.replace(" ", "").replace("？", "?")
	# 缺加数形式：A + ? = N（可能带中文前缀，如 "凑十法：8+?=10"）
	if s.contains("?="):
		var eq := s.split("=")
		if eq.size() >= 2:
			var target := _last_int(eq[eq.size() - 1])
			var nums := eq[0].split("+")
			if nums.size() >= 2:
				var big := _first_int(nums[0])
				var need := maxi(target - big, 0)
				return {"mode": "complement", "big": big, "small": need,
						"target": target, "answer": str(need)}
	# 求和形式：A + B = ?
	var parts := s.replace("=?", "").replace("=", "").split("+")
	if parts.size() >= 2:
		var a := _first_int(parts[0])
		var b := _first_int(parts[1])
		return {"mode": "sum", "big": a, "small": b, "target": a + b, "answer": str(a + b)}
	return {"mode": "sum", "big": 0, "small": 0, "target": 0, "answer": ""}


## 取出字符串中第一个整数（"凑十法：8+?=10" → 8；"8+5=?" → 8）
func _first_int(s: String) -> int:
	for i in range(s.length()):
		var c := s[i]
		if c.is_valid_int():
			var j := i
			while j < s.length() and s[j].is_valid_int():
				j += 1
			return int(s.substr(i, j - i))
	return 0


## 取出字符串中最后一个整数（"凑十法：8+?=10" → 10）
func _last_int(s: String) -> int:
	for i in range(s.length() - 1, -1, -1):
		var c := s[i]
		if c.is_valid_int():
			var j := i
			while j >= 0 and s[j].is_valid_int():
				j -= 1
			return int(s.substr(j + 1, i - j))
	return 0
