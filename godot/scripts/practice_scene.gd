extends "res://scripts/act_base.gd"
##
## 练（Practice）：真实练习会话 / 离线题目，提交判分、讲解、奖励

const Juice := preload("res://scripts/juice.gd")

var _session_id := 1
var _total := 5
var _answered := 0
var _mode := "offline"
var _current_q: Dictionary = {}
var _q_area: VBoxContainer
var _progress_label: Label
var _locked := false
var _combo := 0


func _build() -> void:
	add_heading("🏆 练：小试身手")
	_progress_label = Label.new()
	_progress_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_scroll.add_child(_progress_label)
	_q_area = VBoxContainer.new()
	_q_area.add_theme_constant_override("separation", 10)
	_q_area.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_scroll.add_child(_q_area)

	if _is_offline():
		_mode = "offline"
		_next_offline_question()
	else:
		_mode = "online"
		ApiClient.start_session(ctx["subject"], "PRACTICE", 1, int(ctx["node_id"]), _on_session_start)
		ApiClient.request_failed.connect(_on_req_fail)


func _update_progress() -> void:
	_progress_label.text = "进度：第 %d / %d 题" % [_answered + 1, _total]


func _next_offline_question() -> void:
	_locked = false
	var q: Dictionary = Demo.next_demo_question(_session_id, _answered, _total)
	_current_q = q
	_render_question(q)


func _on_session_start(data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("questionText"):
		_current_q = data
		if data.has("totalQuestions"):
			_total = int(data["totalQuestions"])
		_locked = false
		_render_question(data)
	else:
		_mode = "offline"
		_next_offline_question()


func _render_question(q: Dictionary) -> void:
	_update_progress()
	for c in _q_area.get_children():
		c.queue_free()

	var qt := str(q.get("questionText", ""))
	var lbl := Label.new()
	lbl.text = qt
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(lbl)

	var is_make_ten := (str(ctx.get("node_key", "")) == "math_make_ten") or str(q.get("questionType", "")) == "make_ten"
	if is_make_ten:
		var ab := _parse_add(qt)
		var ui = preload("res://scripts/make_ten_ui.gd").new()
		ui.setup(ab[0], ab[1], false)
		ui.completed.connect(_on_answer)
		ui.ten_reached.connect(_on_ten_reached)
		_q_area.add_child(ui)
	else:
		var opts := str(q.get("options", ""))
		if opts != "" and opts != "null":
			_add_choice_buttons(opts)
		else:
			_add_number_input()


func _add_choice_buttons(opts: String) -> void:
	var items: Array = []
	var parsed: Variant = JSON.parse_string(opts)
	if typeof(parsed) == TYPE_ARRAY:
		items = parsed
	else:
		for s in opts.split(","):
			items.append(s.strip_edges())
	for it in items:
		var b := Button.new()
		b.text = str(it)
		b.custom_minimum_size = Vector2(200, 40)
		b.pressed.connect(_on_answer.bind(str(it)))
		_q_area.add_child(b)


func _add_number_input() -> void:
	var row := HBoxContainer.new()
	var inp := LineEdit.new()
	inp.placeholder_text = "输入答案"
	inp.custom_minimum_size = Vector2(160, 36)
	var ok := Button.new()
	ok.text = "提交"
	ok.custom_minimum_size = Vector2(80, 36)
	ok.pressed.connect(func(): _on_answer(inp.text))
	row.add_child(inp)
	row.add_child(ok)
	_q_area.add_child(row)


func _on_ten_reached() -> void:
	if pet: pet.cheer()


## 答对：连击 + 经验 + 粒子 + 音效 + 连击弹出
func _on_correct_feedback() -> void:
	_combo += 1
	var gain: int = 8 + mini(_combo, 6) * 2
	var r := PetState.add_exp(gain)
	var gp := _q_area.global_position + Vector2(_q_area.size.x * 0.5, _q_area.size.y * 0.25)
	var at := gp - self.global_position
	Juice.burst(self, at, 14)
	Juice.sfx_correct(self)
	if _combo >= 2:
		Juice.popup_text(self, at, "连击 x%d!" % _combo, Color(1.0, 0.7, 0.1))
	if r.leveled_up:
		_on_level_up(r)
	_refresh_hud()


## 答错：连击清零 + 柔和错误音效（不惩罚式红叉）
func _on_wrong_feedback() -> void:
	_combo = 0
	Juice.sfx_wrong(self)


func _on_level_up(r: Dictionary) -> void:
	if pet != null and pet.has_method("set_stage"):
		pet.set_stage(r["new_stage"])
		if pet.has_method("evolve_effect"):
			pet.evolve_effect()
	Juice.sfx_levelup(self)
	toast("升级啦！宠物进化成 %s" % PetState.stage_name())


func _refresh_hud() -> void:
	var root = get_tree().current_scene
	if root != null and root.has_method("refresh_hud"):
		root.refresh_hud()


func _on_answer(answer: String) -> void:
	if _locked:
		return
	_locked = true
	answer = answer.strip_edges()
	if _mode == "offline":
		var res: Dictionary = Demo.demo_answer(_session_id, _current_q, answer, _answered + 1, _total)
		_answered += 1
		_show_result(res)
	else:
		ApiClient.submit_answer(_session_id, int(_current_q.get("questionId", 0)),
			answer, 0, _on_submit)


func _on_submit(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		toast("提交失败")
		_locked = false
		return
	_answered += 1
	_show_result(data)


func _show_result(res: Dictionary) -> void:
	var correct: bool = res.get("isCorrect", false)
	if pet:
		if correct: pet.cheer()
		else: pet.wrong()

	if correct:
		_on_correct_feedback()
	else:
		_on_wrong_feedback()

	var pts: int = int(res.get("pointsEarned", 0))
	if pts != 0:
		PetState.add_energy(pts)
		var root = get_tree().current_scene
		if root and root.has_method("refresh_energy"):
			root.refresh_energy()

	var reward: String = str(res.get("sceneRewardItem", ""))
	if reward != "" and reward != "null":
		PetState.add_item(1, "苹果", int(res.get("sceneRewardCount", 1)))

	var fb := Label.new()
	fb.text = ("✅ 答对啦！+" + str(pts) + " ⚡\n") if correct else ("❌ 再想想～\n")
	fb.add_theme_font_size_override("font_size", 18)
	fb.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	if res.has("explanation"):
		fb.text += str(res["explanation"])
	fb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb.custom_minimum_size = Vector2(560, 0)
	_q_area.add_child(fb)

	var done: bool = res.get("isSessionComplete", false) or res.get("isLastQuestion", false)
	var nb := Button.new()
	if done:
		nb.text = "完成练习，下一幕 →"
		nb.custom_minimum_size = Vector2(240, 44)
		nb.pressed.connect(_on_done)
	else:
		nb.text = "下一题 →"
		nb.custom_minimum_size = Vector2(160, 40)
		var nq: Variant = res.get("nextQuestion", null)
		nb.pressed.connect(_on_next.bind(nq))
	_q_area.add_child(nb)


func _on_next(nq: Variant) -> void:
	if _mode == "offline":
		_next_offline_question()
	elif typeof(nq) == TYPE_DICTIONARY and nq.has("questionText"):
		_current_q = nq
		_locked = false
		_render_question(nq)
	else:
		# 没拿到下一题但也没标记完成：再请求一次 start 不现实，转离线兜底
		_mode = "offline"
		_next_offline_question()


func _on_done() -> void:
	emit_signal("finished")


func _on_req_fail(msg: String) -> void:
	if _mode == "online" and _answered == 0:
		_mode = "offline"
		_next_offline_question()
	else:
		toast(msg)
