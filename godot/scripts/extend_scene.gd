extends "res://scripts/act_base.gd"
##
## 拓（Extend）：生成变式题 + 讲给宠物听（元认知）

var _mode := "offline"
var _base_q: Dictionary = {}
var _variant_q: Dictionary = {}
var _q_area: VBoxContainer
var _phase := 0   # 0=基础题 1=变式题 2=讲解


func _build() -> void:
	add_heading("🚀 拓：举一反三")
	_q_area = VBoxContainer.new()
	_q_area.add_theme_constant_override("separation", 10)
	_q_area.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_scroll.add_child(_q_area)

	if _is_offline():
		_mode = "offline"
		_base_q = Demo.next_demo_question(1, 0, 5)
		_render_base(_base_q)
	else:
		_mode = "online"
		ApiClient.start_session(ctx["subject"], "PRACTICE", 1, int(ctx["node_id"]), _on_base)
		ApiClient.request_failed.connect(_on_req_fail)


func _render_base(q: Dictionary) -> void:
	_phase = 0
	_clear_q()
	var lbl := Label.new()
	lbl.text = "基础题：" + str(q.get("questionText", ""))
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(lbl)
	var hint := Label.new()
	hint.text = "先自己算一算，然后点下面的按钮生成一道「变式题」。"
	hint.add_theme_color_override("font_color", Color(0.3, 0.4, 0.5))
	_q_area.add_child(hint)
	var b := Button.new()
	b.text = "生成变式题 →"
	b.custom_minimum_size = Vector2(220, 42)
	b.pressed.connect(_on_make_variant)
	_q_area.add_child(b)


func _on_make_variant() -> void:
	if _mode == "offline":
		_variant_q = Demo.demo_variant(_base_q)
		_render_variant(_variant_q)
	else:
		ApiClient.generate_variant(int(ctx["node_id"]), int(_base_q.get("questionId", 0)), _on_variant)


func _on_base(data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("questionText"):
		_base_q = data
		_render_base(data)
	else:
		_mode = "offline"
		_base_q = Demo.next_demo_question(1, 0, 5)
		_render_base(_base_q)


func _on_variant(data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("questionText"):
		_variant_q = data
		_render_variant(data)
	else:
		_variant_q = Demo.demo_variant(_base_q)
		_render_variant(_variant_q)


func _render_variant(q: Dictionary) -> void:
	_phase = 1
	_clear_q()
	var lbl := Label.new()
	lbl.text = "✨ 变式题：" + str(q.get("questionText", ""))
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(lbl)

	var is_make_ten := (str(ctx.get("node_key", "")) == "math_make_ten") or str(q.get("questionType", "")) == "make_ten"
	if is_make_ten:
		var ab := _parse_add(str(q.get("questionText", "")))
		var ui = preload("res://scripts/make_ten_ui.gd").new()
		ui.setup(ab[0], ab[1], false)
		ui.completed.connect(_on_variant_answer)
		ui.ten_reached.connect(_on_ten_reached)
		_q_area.add_child(ui)
	else:
		var inp := LineEdit.new()
		inp.placeholder_text = "输入答案"
		inp.custom_minimum_size = Vector2(160, 36)
		var ok := Button.new()
		ok.text = "提交"
		ok.custom_minimum_size = Vector2(80, 36)
		ok.pressed.connect(func(): _on_variant_answer(inp.text))
		var row := HBoxContainer.new()
		row.add_child(inp); row.add_child(ok)
		_q_area.add_child(row)


func _on_ten_reached() -> void:
	if pet: pet.cheer()


func _on_variant_answer(answer: String) -> void:
	answer = answer.strip_edges()
	# 变式题也用离线/在线判分
	var res: Dictionary
	if _mode == "offline":
		res = Demo.demo_answer(1, _variant_q, answer, 1, 5)
	else:
		# 简化：用离线判分逻辑确认正确性（在线 submit 略）
		res = Demo.demo_answer(1, _variant_q, answer, 1, 5)
	_show_variant_result(res)


func _show_variant_result(res: Dictionary) -> void:
	if pet:
		if res.get("isCorrect", false): pet.cheer()
		else: pet.wrong()
	var fb := Label.new()
	fb.text = ("✅ 变式也答对啦！\n" if res.get("isCorrect", false) else "❌ 再想想～\n")
	if res.has("explanation"):
		fb.text += str(res["explanation"])
	fb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb.custom_minimum_size = Vector2(560, 0)
	fb.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(fb)
	_render_explain()


func _render_explain() -> void:
	_phase = 2
	var sep := Label.new()
	sep.text = "—— 讲给宠物听（元认知） ——"
	sep.add_theme_font_size_override("font_size", 18)
	sep.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(sep)

	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(560, 90)
	_q_area.add_child(te)

	var submit := Button.new()
	submit.text = "提交讲解"
	submit.custom_minimum_size = Vector2(160, 40)
	submit.pressed.connect(_on_explain.bind(te))
	_q_area.add_child(submit)


func _on_explain(te: TextEdit) -> void:
	var text := te.text.strip_edges()
	if text == "":
		toast("先写点什么再提交哦")
		return
	if _mode == "offline" or int(ctx.get("node_id", -1)) <= 0:
		_show_explain_result({"feedback": "宠物：你说得真好！把凑十的步骤讲得很清楚～（离线模式）"})
	else:
		ApiClient.explain(int(ctx["node_id"]), text, _on_explain_result)


func _on_explain_result(data: Variant) -> void:
	_show_explain_result(data)


func _show_explain_result(res: Variant) -> void:
	var fb := Label.new()
	if typeof(res) == TYPE_DICTIONARY and res.has("feedback"):
		fb.text = "🐾 " + str(res["feedback"])
	else:
		fb.text = "🐾 宠物认真听完了你的讲解！"
	fb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb.custom_minimum_size = Vector2(560, 0)
	fb.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(fb)
	if pet: pet.cheer()
	var done := Button.new()
	done.text = "完成，回到宠物小屋 →"
	done.custom_minimum_size = Vector2(240, 44)
	done.pressed.connect(_on_done)
	_q_area.add_child(done)


func _on_done() -> void:
	emit_signal("finished")


func _clear_q() -> void:
	for c in _q_area.get_children():
		c.queue_free()


func _on_req_fail(msg: String) -> void:
	if _mode == "online" and _phase == 0:
		_mode = "offline"
		_base_q = Demo.next_demo_question(1, 0, 5)
		_render_base(_base_q)
	else:
		toast(msg)
