extends "res://scripts/base_scene.gd"
##
## 学程地图：游戏化「学科大陆」地图
## 顶部大陆切换栏（语文大陆 / 数学大陆 / 英语大陆），点选后加载该学科的
## 主题岛 + 关卡点，点击关卡弹出详情卡片。数据来自后端
## GET /study/subjects 与 GET /study/worlds/{subject}，离线自动回退示例。

const ISLAND_W := 300
const ISLAND_H := 360
const NODE_SIZE := 72
const ISLAND_PAD := 24
const ISLAND_GAP := 120

const SUBJECT_NAMES := {
	"chinese": "语文大陆",
	"math": "数学大陆",
	"english": "英语大陆",
}

var _vbox: VBoxContainer
var _tabs: HBoxContainer
var _tab_buttons: Array = []

var _scroll: ScrollContainer
var _map: Control
var _world_layer: Control          # 主题岛 + 路径的容器，重载时整体清空
var _detail: PanelContainer
var _detail_title: Label
var _detail_desc: Label
var _detail_meta: Label
var _detail_stars: Label
var _detail_btn: Button

var _selected: Dictionary = {}
var _islands: Array = []           # {panel, root, nodes:[{ctrl,data,island,idx,pos}]}
var _all_nodes: Array = []         # 全部关卡点，用于画路径与引导

var _subjects: Array = []          # [{key, stars, completed, total}]
var _current_subject: String = ""


func _on_setup() -> void:
	back_scene_path = "res://scenes/main_menu.tscn"
	_build_layout()
	_build_detail()
	ApiClient.request_failed.connect(_on_req_fail)
	_load_subjects()
	prints("[WorldMap] _on_setup 完成：布局容器=", _vbox != null, " 地图层=", _world_layer != null, " 大陆栏按钮数=", _tab_buttons.size())


# ===================== 布局：大陆栏 + 滚动地图 =====================

func _build_layout() -> void:
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 10)
	content.add_child(_vbox)

	# 顶部大陆切换栏
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tabs.custom_minimum_size = Vector2(0, 60)
	_vbox.add_child(_tabs)

	# 地图滚动区（横向滚动，纵向禁用）
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vbox.add_child(_scroll)

	_map = Control.new()
	_map.custom_minimum_size = Vector2(1200, 560)
	_map.size = Vector2(1200, 560)
	_scroll.add_child(_map)

	# 海洋背景
	var bg := ColorRect.new()
	bg.color = Color(0.82, 0.93, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(bg)

	# 云朵装饰（在岛屿下层）
	for i in range(6):
		var cloud := PanelContainer.new()
		var cw := 90 + (i % 3) * 35
		var ch := 28 + (i % 2) * 10
		cloud.position = Vector2(60 + i * 260, 30 + (i % 3) * 95)
		cloud.custom_minimum_size = Vector2(cw, ch)
		cloud.size = Vector2(cw, ch)
		cloud.modulate = Color(1, 1, 1, 0.45)
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cstyle := StyleBoxFlat.new()
		cstyle.bg_color = Color(1, 1, 1, 0.95)
		cstyle.corner_radius_top_left = 14
		cstyle.corner_radius_top_right = 14
		cstyle.corner_radius_bottom_left = 14
		cstyle.corner_radius_bottom_right = 14
		cloud.add_theme_stylebox_override("panel", cstyle)
		_map.add_child(cloud)

	# 世界层：主题岛与路径都挂在它下面，重载时整体清空
	_world_layer = Control.new()
	_world_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(_world_layer)


# ===================== 大陆切换栏 =====================

func _load_subjects() -> void:
	if ApiClient.token != "":
		ApiClient.get_subjects(_on_subjects)
	else:
		_subjects = _demo_subject_list()
		_populate_tabs()
		_select_subject("math")


func _on_subjects(data: Variant) -> void:
	_subjects.clear()
	if typeof(data) == TYPE_ARRAY and data.size() > 0:
		for d in data:
			if typeof(d) != TYPE_DICTIONARY:
				continue
			var key: String = _safe_str(d, "subject", "")
			if key == "":
				continue
			_subjects.append({
				"key": key,
				"stars": int(d.get("totalStars", 0)),
				"completed": int(d.get("completedNodes", 0)),
				"total": int(d.get("totalNodes", 0)),
			})
	if _subjects.is_empty():
		_subjects = _demo_subject_list()
	_populate_tabs()
	# 默认优先选中数学大陆，否则选第一块
	var want := "math"
	var found := false
	for s in _subjects:
		if s["key"] == want:
			found = true
			break
	if found:
		_select_subject(want)
	elif not _subjects.is_empty():
		_select_subject(_subjects[0]["key"])


func _populate_tabs() -> void:
	var scale := _font_scale()
	for c in _tabs.get_children():
		c.queue_free()
	_tab_buttons.clear()
	for s in _subjects:
		var btn := Button.new()
		var key: String = str(s["key"])
		var name: String = _subject_name(key)
		var completed: int = int(s["completed"])
		var total: int = int(s["total"])
		var stars: int = int(s["stars"])
		var bar := ""
		if total > 0:
			var filled: int = completed * 8 / total
			if filled < 0: filled = 0
			if filled > 8: filled = 8
			bar = "█".repeat(filled) + "░".repeat(8 - filled)
		else:
			bar = "░░░░░░░░"
		var line1 := "%s" % name
		var line2 := "%s  ★%d" % [bar, stars]
		var line3 := "%d/%d" % [completed, total]
		btn.text = "%s\n%s\n%s" % [line1, line2, line3]
		btn.add_theme_font_size_override("font_size", int(12 * scale))
		btn.custom_minimum_size = Vector2(170, 72) * scale
		btn.pressed.connect(_on_tab_pressed.bind(key))
		btn.set_meta("subject_key", key)
		_tabs.add_child(btn)
		_tab_buttons.append(btn)
	_highlight_tab(_current_subject)


func _on_tab_pressed(key: String) -> void:
	_select_subject(key)


func _select_subject(key: String) -> void:
	_current_subject = key
	set_title(_subject_name(key))
	_highlight_tab(key)
	_hide_detail()
	_load_current()


func _highlight_tab(key: String) -> void:
	for b: Button in _tab_buttons:
		var selected: bool = b.has_meta("subject_key") and str(b.get_meta("subject_key")) == key
		_style_tab(b, selected)


func _style_tab(btn: Button, selected: bool) -> void:
	var scale := _font_scale()
	var sb := StyleBoxFlat.new()
	if selected:
		sb.bg_color = Color(0.2, 0.55, 0.55)
		sb.border_color = Color(1, 1, 1, 0.8)
	else:
		sb.bg_color = Color(1, 1, 1, 0.85)
		sb.border_color = Color(0.6, 0.85, 0.9)
	sb.border_width_left = 2; sb.border_width_top = 2
	sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.corner_radius_top_left = 14; sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14; sb.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1) if selected else Color(0.15, 0.35, 0.4))


func _subject_name(key: String) -> String:
	if SUBJECT_NAMES.has(key):
		return SUBJECT_NAMES[key]
	return key.capitalize()


func _safe_str(dict: Dictionary, key: String, fallback: String = "") -> String:
	var v: Variant = dict.get(key)
	if v == null:
		return fallback
	return str(v)


# ===================== 加载当前大陆的世界地图 =====================

func _load_current() -> void:
	_clear_world()
	if ApiClient.token != "":
		ApiClient.get_world_map(_current_subject, _on_world_map)
	else:
		_load_demo_world()


func _clear_world() -> void:
	for c in _world_layer.get_children():
		_world_layer.remove_child(c)
		c.queue_free()
	_islands.clear()
	_all_nodes.clear()


func _on_world_map(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("nodes"):
		_load_demo_world()
		return
	var raw_nodes: Variant = data["nodes"]
	var roots: Array = raw_nodes if raw_nodes != null else []
	if roots.is_empty():
		_load_demo_world()
		return
	_build_islands(roots)
	_show_guide()


## 网络/接口失败时统一回退：学科栏没数据→示例学科；世界地图空白→示例地图。
func _on_req_fail(_msg: String) -> void:
	if _subjects.is_empty():
		_subjects = _demo_subject_list()
		_populate_tabs()
		_select_subject("math")
		return
	if _world_layer.get_child_count() == 0:
		_load_demo_world()


func _load_demo_world() -> void:
	var roots: Array = _demo_world(_current_subject)
	_build_islands(roots)
	_show_guide()


# ===================== 构建主题岛与关卡点 =====================

func _build_islands(roots: Array) -> void:
	var scale := _font_scale()
	var map_w := int(roots.size() * (ISLAND_W + ISLAND_GAP) + ISLAND_GAP)
	var map_h := 620
	_map.custom_minimum_size = Vector2(map_w, map_h)
	_map.size = Vector2(map_w, map_h)

	for i in range(roots.size()):
		var root: Dictionary = roots[i]
		var ix := ISLAND_GAP + i * (ISLAND_W + ISLAND_GAP)
		var iy := 60
		_build_island(i, root, ix, iy, scale)

	_draw_paths()


func _build_island(idx: int, root: Dictionary, x: int, y: int, scale: float) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(x, y)
	panel.custom_minimum_size = Vector2(ISLAND_W, ISLAND_H)
	panel.size = Vector2(ISLAND_W, ISLAND_H)

	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = _island_color(idx)
	pstyle.corner_radius_top_left = 32
	pstyle.corner_radius_top_right = 32
	pstyle.corner_radius_bottom_left = 32
	pstyle.corner_radius_bottom_right = 32
	pstyle.border_color = Color(1, 1, 1, 0.65)
	pstyle.border_width_left = 4
	pstyle.border_width_top = 4
	pstyle.border_width_right = 4
	pstyle.border_width_bottom = 4
	pstyle.shadow_color = Color(0.1, 0.25, 0.3, 0.2)
	pstyle.shadow_size = 14
	pstyle.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", pstyle)
	_world_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = ISLAND_PAD
	vbox.offset_top = ISLAND_PAD
	vbox.offset_right = -ISLAND_PAD
	vbox.offset_bottom = -ISLAND_PAD
	panel.add_child(vbox)

	var title := Label.new()
	title.text = _safe_str(root, "name", "主题岛")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(22 * scale))
	title.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _safe_str(root, "description", "")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", int(13 * scale))
	subtitle.add_theme_color_override("font_color", Color(0.25, 0.45, 0.5))
	vbox.add_child(subtitle)

	var grid := Control.new()
	grid.custom_minimum_size = Vector2(ISLAND_W - ISLAND_PAD * 2, ISLAND_H - 118)
	vbox.add_child(grid)

	var raw_children: Variant = root.get("children", [])
	var children: Array = raw_children if raw_children != null else []
	var island_nodes: Array = []
	var content_w: int = ISLAND_W - ISLAND_PAD * 2
	var content_h: int = ISLAND_H - 118
	for j in range(children.size()):
		var node: Dictionary = children[j]
		var btn := _build_node_button(node, idx, j, scale)
		var pos := _node_position(j, children.size(), content_w, content_h)
		btn.position = pos
		grid.add_child(btn)

		var record := {
			"ctrl": btn, "data": node, "island": idx, "idx": j,
			"pos": Vector2(x + ISLAND_PAD + pos.x + NODE_SIZE / 2, y + ISLAND_PAD + pos.y + NODE_SIZE / 2)
		}
		island_nodes.append(record)
		_all_nodes.append(record)

	if children.is_empty():
		var empty := Label.new()
		empty.text = "暂无关卡"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", int(14 * scale))
		empty.add_theme_color_override("font_color", Color(0.45, 0.55, 0.6))
		empty.custom_minimum_size = Vector2(content_w, content_h)
		grid.add_child(empty)

	_islands.append({"panel": panel, "root": root, "nodes": island_nodes})


func _node_position(j: int, total: int, content_w: int, content_h: int) -> Vector2:
	var cols := 2
	var rows := (total + cols - 1) / cols
	if rows < 1:
		rows = 1
	var pad_x := 16
	var pad_y := 12
	var avail_w := content_w - pad_x * 2
	var avail_h := content_h - pad_y * 2
	var cell_w: float = avail_w / float(cols)
	var cell_h: float = avail_h / float(rows) if rows > 1 else float(avail_h)
	var row: int = j / cols
	var col_raw: int = j % cols
	var col: int = col_raw if (row % 2) == 0 else (cols - 1 - col_raw)
	var px := pad_x + col * cell_w + (cell_w - NODE_SIZE) / 2.0
	var py := pad_y + row * cell_h + (cell_h - NODE_SIZE) / 2.0
	return Vector2(px, py)


func _build_node_button(node: Dictionary, _island_idx: int, _node_idx: int, scale: float) -> Button:
	var unlocked: bool = node.get("isUnlocked", true)
	var completed: bool = node.get("isCompleted", false)
	var stars: int = int(node.get("starRating", 0))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE) * scale
	btn.size = Vector2(NODE_SIZE, NODE_SIZE) * scale

	var base_color: Color
	if not unlocked:
		base_color = Color(0.72, 0.72, 0.72)
	elif completed:
		base_color = Color(0.36, 0.79, 0.65)
	else:
		base_color = Color(0.94, 0.62, 0.15)

	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = int(NODE_SIZE * scale / 2)
	normal.corner_radius_top_right = int(NODE_SIZE * scale / 2)
	normal.corner_radius_bottom_left = int(NODE_SIZE * scale / 2)
	normal.corner_radius_bottom_right = int(NODE_SIZE * scale / 2)
	normal.bg_color = base_color
	normal.border_color = Color(1, 1, 1, 0.7)
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.35)
	normal.shadow_size = 10
	normal.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_stylebox_override("disabled", normal)

	var star_str: String = "★".repeat(stars) if stars > 0 else ""
	if not unlocked:
		star_str = "🔒"
	btn.text = "%s\n%s" % [_safe_str(node, "name", "关卡"), star_str]
	btn.add_theme_font_size_override("font_size", int(11 * scale))
	btn.add_theme_color_override("font_color", Color(1, 1, 1))

	btn.pressed.connect(_on_node_selected.bind(node))
	return btn


func _draw_paths() -> void:
	if _all_nodes.size() < 2:
		return

	for isl in _islands:
		var nodes: Array = isl["nodes"]
		for i in range(nodes.size() - 1):
			_add_path(nodes[i]["pos"], nodes[i + 1]["pos"], true, false)

	for i in range(_islands.size() - 1):
		var cur_nodes: Array = _islands[i]["nodes"]
		var next_nodes: Array = _islands[i + 1]["nodes"]
		if cur_nodes.is_empty() or next_nodes.is_empty():
			continue
		var last_node: Dictionary = cur_nodes[cur_nodes.size() - 1]
		var first_next: Dictionary = next_nodes[0]
		var connected: bool = bool(first_next["data"].get("isUnlocked", true))
		_add_path(last_node["pos"], first_next["pos"], connected, true)


func _add_path(from_pos: Vector2, to_pos: Vector2, connected: bool, inter_island: bool) -> void:
	var color: Color = Color(0.4, 0.65, 0.35) if connected else Color(0.72, 0.72, 0.72)
	var dashed := not connected

	var cp1: Vector2
	var cp2: Vector2
	if inter_island:
		# 跨岛路径：控制点固定在两个岛的间隙中点，避免曲线穿入岛屿
		var gap_mid_x := (from_pos.x + to_pos.x) / 2.0
		cp1 = Vector2(gap_mid_x, from_pos.y)
		cp2 = Vector2(gap_mid_x, to_pos.y)
	else:
		# 岛内路径：根据主次方向选择控制点，保持小径在岛内部
		var dx: float = abs(to_pos.x - from_pos.x)
		var dy: float = abs(to_pos.y - from_pos.y)
		var mid := (from_pos + to_pos) / 2.0
		if dx >= dy:
			cp1 = Vector2(mid.x, from_pos.y)
			cp2 = Vector2(mid.x, to_pos.y)
		else:
			cp1 = Vector2(from_pos.x, mid.y)
			cp2 = Vector2(to_pos.x, mid.y)

	if dashed:
		var step_count := 20
		for k in range(step_count):
			var t0 := float(k) / float(step_count)
			var t1 := float(k + 0.5) / float(step_count)
			var seg := Line2D.new()
			seg.width = 3
			seg.default_color = color
			seg.add_point(_bezier(from_pos, cp1, cp2, to_pos, t0))
			seg.add_point(_bezier(from_pos, cp1, cp2, to_pos, t1))
			_world_layer.add_child(seg)
	else:
		var line := Line2D.new()
		line.width = 5
		line.default_color = color
		for t in range(17):
			var tt := float(t) / 16.0
			line.add_point(_bezier(from_pos, cp1, cp2, to_pos, tt))
		_world_layer.add_child(line)


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t


# ===================== 详情卡片 =====================

func _build_detail() -> void:
	_detail = PanelContainer.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_detail.offset_top = -220
	_detail.offset_bottom = -24
	_detail.modulate.a = 0.0
	add_child(_detail)   # 挂到场景根，浮在 content 之上

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_color = Color(0.6, 0.85, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	_detail.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24
	vbox.offset_top = 20
	vbox.offset_right = -24
	vbox.offset_bottom = -20
	_detail.add_child(vbox)

	_detail_title = Label.new()
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title.add_theme_font_size_override("font_size", int(22 * _font_scale()))
	_detail_title.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	vbox.add_child(_detail_title)

	_detail_meta = Label.new()
	_detail_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_meta.add_theme_font_size_override("font_size", int(13 * _font_scale()))
	_detail_meta.add_theme_color_override("font_color", Color(0.25, 0.45, 0.5))
	vbox.add_child(_detail_meta)

	_detail_desc = Label.new()
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_font_size_override("font_size", int(14 * _font_scale()))
	_detail_desc.add_theme_color_override("font_color", Color(0.2, 0.4, 0.45))
	vbox.add_child(_detail_desc)

	_detail_stars = Label.new()
	_detail_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_stars.add_theme_font_size_override("font_size", int(18 * _font_scale()))
	_detail_stars.add_theme_color_override("font_color", Color(0.94, 0.62, 0.15))
	vbox.add_child(_detail_stars)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	_detail_btn = Button.new()
	_detail_btn.custom_minimum_size = Vector2(200, 44) * _font_scale()
	_detail_btn.pressed.connect(_on_start)
	_detail_btn.add_theme_font_size_override("font_size", int(16 * _font_scale()))
	btn_row.add_child(_detail_btn)

	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(100, 44) * _font_scale()
	close.pressed.connect(_hide_detail)
	close.add_theme_font_size_override("font_size", int(16 * _font_scale()))
	btn_row.add_child(close)


func _on_node_selected(node: Dictionary) -> void:
	_selected = node
	_detail_title.text = _safe_str(node, "name", "关卡")
	_detail_desc.text = _safe_str(node, "description", "")

	var diff: int = int(node.get("difficulty", 1))
	var unlocked: bool = node.get("isUnlocked", true)
	var completed: bool = node.get("isCompleted", false)
	var stars: int = int(node.get("starRating", 0))

	_detail_meta.text = "难度 %d · %s" % [diff, "已解锁" if unlocked else "未解锁"]
	if completed:
		_detail_stars.text = "★".repeat(stars) + "   已完成"
	elif unlocked:
		_detail_stars.text = "☆☆☆   去挑战拿星星"
	else:
		_detail_stars.text = "🔒   完成前置关卡后解锁"

	_detail_btn.disabled = not unlocked
	if unlocked:
		_detail_btn.text = "开始挑战"
	else:
		_detail_btn.text = "尚未解锁"

	var tw := create_tween()
	tw.tween_property(_detail, "modulate:a", 1.0, 0.25)


func _hide_detail() -> void:
	var tw := create_tween()
	tw.tween_property(_detail, "modulate:a", 0.0, 0.2)


func _on_start() -> void:
	if _selected.is_empty():
		return
	Demo.current_node = {
		"id": int(_selected.get("nodeId", -1)),
		"key": _safe_str(_selected, "nodeKey", ""),
		"subject": _current_subject
	}
	get_tree().change_scene_to_file("res://scenes/learning_loop.tscn")


func _show_guide() -> void:
	for rec in _all_nodes:
		var node: Dictionary = rec["data"]
		if node.get("isUnlocked", true) and not node.get("isCompleted", false):
			if pet:
				pet.wave()
			toast("小精灵：先去「%s」探险吧！" % _safe_str(node, "name", "关卡"))
			return
	if pet:
		pet.cheer()


func _island_color(idx: int) -> Color:
	var palette := [
		Color(0.75, 0.92, 0.72),
		Color(0.95, 0.82, 0.68),
		Color(0.78, 0.86, 0.96),
		Color(0.96, 0.78, 0.84),
		Color(0.92, 0.88, 0.72),
	]
	return palette[idx % palette.size()]


# ===================== 离线示例数据（三块大陆） =====================

func _demo_subject_list() -> Array:
	var keys := ["chinese", "math", "english"]
	var list := []
	for k in keys:
		var roots := _demo_world(k)
		var total := 0
		var completed := 0
		var stars := 0
		for r in roots:
			for ch in r.get("children", []):
				total += 1
				if ch.get("isCompleted", false):
					completed += 1
				stars += int(ch.get("starRating", 0))
		list.append({"key": k, "stars": stars, "completed": completed, "total": total})
	return list


func _demo_world(subject: String) -> Array:
	match subject:
		"chinese":
			return [
				{
					"name": "拼音岛",
					"description": "声母与韵母的快乐乐园",
					"children": [
						{"nodeId": 101, "name": "声母乐园", "description": "认识 23 个声母，读准每个音", "difficulty": 1, "isUnlocked": true, "isCompleted": true, "starRating": 2, "nodeKey": ""},
						{"nodeId": 102, "name": "韵母王国", "description": "单韵母与复韵母的正确拼读", "difficulty": 1, "isUnlocked": true, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
				{
					"name": "识字岛",
					"description": "在故事中认识常用汉字",
					"children": [
						{"nodeId": 103, "name": "趣味识字", "description": "通过图画与儿歌识记汉字", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
						{"nodeId": 104, "name": "偏旁部首", "description": "理解偏旁，归类记忆汉字", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
				{
					"name": "阅读岛",
					"description": "从绘本走向自主阅读",
					"children": [
						{"nodeId": 105, "name": "绘本阅读", "description": "跟着小精灵读绘本，培养语感", "difficulty": 3, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
			]
		"english":
			return [
				{
					"name": "字母岛",
					"description": "ABC 启蒙与大小写配对",
					"children": [
						{"nodeId": 201, "name": "ABC 启蒙", "description": "认识 26 个英文字母的发音", "difficulty": 1, "isUnlocked": true, "isCompleted": true, "starRating": 3, "nodeKey": ""},
						{"nodeId": 202, "name": "大小写配对", "description": "把大写和小写字母正确配对", "difficulty": 1, "isUnlocked": true, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
				{
					"name": "单词岛",
					"description": "在生活情境里积累词汇",
					"children": [
						{"nodeId": 203, "name": "动物单词", "description": "认识常见动物的英文名称", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
						{"nodeId": 204, "name": "食物单词", "description": "认识常见食物的英文名称", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
				{
					"name": "口语岛",
					"description": "开口说，敢表达",
					"children": [
						{"nodeId": 205, "name": "日常问候", "description": "用英语打招呼、介绍自己", "difficulty": 3, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
			]
		_:
			# 数学大陆（默认）
			return [
				{
					"name": "加法岛",
					"description": "10以内加法与凑十法",
					"children": [
						{"nodeId": 1, "name": "凑十法", "description": "学会看大数拆小数，凑成十再加余数", "difficulty": 1, "isUnlocked": true, "isCompleted": false, "starRating": 0, "nodeKey": "math_make_ten"},
						{"nodeId": 2, "name": "10以内加减", "description": "掌握10以内的加法和减法运算", "difficulty": 1, "isUnlocked": true, "isCompleted": true, "starRating": 2, "nodeKey": ""},
					]
				},
				{
					"name": "进阶岛",
					"description": "20以内进位加法和退位减法",
					"children": [
						{"nodeId": 3, "name": "进位加法", "description": "学会凑十法计算20以内进位加法", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
						{"nodeId": 4, "name": "退位减法", "description": "学会破十法计算20以内退位减法", "difficulty": 2, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
				{
					"name": "图形村",
					"description": "认识基本图形",
					"children": [
						{"nodeId": 5, "name": "认识图形", "description": "认识圆形、正方形、三角形等基本图形", "difficulty": 3, "isUnlocked": false, "isCompleted": false, "starRating": 0, "nodeKey": ""},
					]
				},
			]
