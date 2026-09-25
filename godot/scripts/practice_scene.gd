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
var _wrong_streak := 0


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
		# 记录后端会话 id：后续 submit 都要带它（此前固定用 1 会提交失败）
		if data.has("sessionId"):
			_session_id = int(data["sessionId"])
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
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(lbl)

	# 凑十交互：math_make_ten 节点 / make_ten 题型 / 后端 SCENE_DRAG 补十题
	var qt_type := str(q.get("questionType", ""))
	var is_make_ten := (str(ctx.get("node_key", "")) == "math_make_ten") \
		or ["make_ten", "SCENE_DRAG"].has(qt_type)
	if is_make_ten:
		var pq := _parse_question(qt)
		var ui = preload("res://scripts/make_ten_ui.gd").new()
		ui.setup(int(pq["big"]), int(pq["small"]), false, str(pq["mode"]))
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
		var label := ""
		var value := ""
		if typeof(it) == TYPE_DICTIONARY:
			label = str(it.get("text", ""))
			value = str(it.get("key", ""))
		else:
			label = str(it).strip_edges()
			value = label
		b.text = label if label != "" else value
		b.custom_minimum_size = Vector2(200, 40)
		b.pressed.connect(_on_answer.bind(value))
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


## 答对：连击 + 经验 + 粒子 + 音效 + 连击弹出（轻微震屏增加爽感）
func _on_correct_feedback() -> void:
	_combo += 1
	_wrong_streak = 0
	var gain: int = 8 + mini(_combo, 6) * 2
	var r := PetState.add_exp(gain)
	var gp := _q_area.global_position + Vector2(_q_area.size.x * 0.5, _q_area.size.y * 0.25)
	var at := gp - self.global_position
	Juice.burst(self, at, 14 + mini(_combo, 4) * 2)
	Juice.sfx_correct(self)
	Juice.shake(self, 4.0, 0.24)
	if _combo >= 2:
		Juice.popup_text(self, at, "连击 x%d!" % _combo, Color(1.0, 0.7, 0.1))
	if _combo == 3:
		pet_say("哇！三连击，太厉害了！")
	if r.leveled_up:
		_on_level_up(r)
	_refresh_hud()


## 答错：连击清零 + 柔和错误反馈（轻微震屏提示，不打击）
func _on_wrong_feedback() -> void:
	_combo = 0
	_wrong_streak += 1
	Juice.sfx_wrong(self)
	Juice.shake(self, 5.0, 0.3)
	if pet and pet.has_method("think") and _wrong_streak >= 2:
		pet.think()


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

	# 智能引导：连续答错后给更细的步骤提示（拆解当前题），不直接给答案数字
	if not correct:
		pet_say(_pep_talk(_wrong_streak))
		if _wrong_streak >= 2:
			var tip := _step_hint()
			if tip != "":
				var hint := Label.new()
				hint.text = "💡 " + tip
				hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				hint.custom_minimum_size = Vector2(560, 0)
				hint.add_theme_font_size_override("font_size", 16)
				hint.add_theme_color_override("font_color", Color(0.45, 0.32, 0.1))
				_q_area.add_child(hint)

	var done: bool = res.get("isSessionComplete", false) or res.get("isLastQuestion", false)
	# 离线模式答错：允许“再试一次”（本地判分，不重复提交服务器）
	if not correct and _mode == "offline" and not done:
		var retry := Button.new()
		retry.text = "🔁 再试一次"
		retry.custom_minimum_size = Vector2(200, 48)
		retry.pressed.connect(_on_retry_offline)
		UiKit.style_button(retry, false, 12, 16)
		_q_area.add_child(retry)
		_answered -= 1   # 撤销刚才那次离线计数，重试不计入进度

	var nb := Button.new()
	if done:
		nb.text = "完成练习，下一幕 →"
		nb.custom_minimum_size = Vector2(240, 48)
		nb.pressed.connect(_on_done)
	else:
		nb.text = "下一题 →"
		nb.custom_minimum_size = Vector2(180, 48)
		var nq: Variant = res.get("nextQuestion", null)
		nb.pressed.connect(_on_next.bind(nq))
	nb.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	_q_area.add_child(nb)
	# 把“下一题/完成”按钮做视觉主次：主操作用强调色
	if done or correct:
		UiKit.style_button(nb, true, 12, 16)
	else:
		UiKit.style_button(nb, false, 12, 16)


## 鼓励话术（按连续错误次数递进）
func _pep_talk(streak: int) -> String:
	if streak <= 1:
		return "没关系，再看看这题～"
	if streak == 2:
		return "别急，慢慢想，小精灵陪着你！"
	return "换个思路试试，你一定行！💪"


## 针对凑十题给出“不剧透答案”的步骤提示
func _step_hint() -> String:
	var pq := _parse_question(str(_current_q.get("questionText", "")))
	if str(pq.get("mode", "")) == "complement":
		var big: int = int(pq["big"])
		var need: int = int(pq["small"])
		if need == 0:
			return "已经正好是 10 啦，数一数十格阵里有几个？"
		return "看大数 %d：先不动它，数一数还空着 %d 个格子——把这 %d 个绿苹果点进去就满 10 了。" % [big, need, need]
	if str(pq.get("mode", "")) == "sum":
		var big: int = int(pq["big"])
		var small: int = int(pq["small"])
		return "看大数 %d，需要先补 %d 个凑成 10；补完后还剩 %d 个，10 加 %d 等于几？" % [big, 10 - big, maxi(small - (10 - big), 0), maxi(small - (10 - big), 0)]
	return "用十格阵数一数，或者用手指头帮忙～"


func _on_retry_offline() -> void:
	_locked = false
	_wrong_streak = 0
	_render_question(_current_q)


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
