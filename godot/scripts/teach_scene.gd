extends "res://scripts/act_base.gd"
##
## 教（Teach）：讲解绘本 + 宠物演示 + 凑十引导交互
## 每张教学卡片独立成卡，可单张朗读，也可「自动讲」逐张滚动播放。

## 卡片数据：{ control: Control, text: String }
var _cards: Array = []
var _auto_play := false
var _auto_idx := 0
var _voice_id := ""


func _build() -> void:
	_add_header_bar()
	var cards: Array = []
	if ctx.has("teaching") and typeof(ctx["teaching"]) == TYPE_DICTIONARY and ctx["teaching"].has("cards"):
		cards = ctx["teaching"]["cards"]
	if cards.is_empty():
		add_paragraph("（暂无教学卡片）")
		_finish_button()
		return
	for card in cards:
		_render_card(card)
	_finish_button()
	_ensure_voice_id()


func _add_header_bar() -> void:
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(hb)

	var title := Label.new()
	title.text = "📖 教：先听小精灵讲一讲"
	title.add_theme_font_size_override("font_size", font_size(22))
	title.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)

	var auto := CheckButton.new()
	auto.text = "自动讲"
	auto.add_theme_font_size_override("font_size", font_size(16))
	auto.pressed.connect(_on_toggle_auto.bind(auto))
	hb.add_child(auto)


func _render_card(card: Dictionary) -> void:
	var t := str(card.get("type", ""))
	var title := str(card.get("title", ""))
	var content := str(card.get("content", ""))
	var speech_parts: PackedStringArray = []
	if not title.is_empty():
		speech_parts.append(title)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.6)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.add_theme_constant_override("margin_left", 14)
	panel.add_theme_constant_override("margin_top", 12)
	panel.add_theme_constant_override("margin_right", 14)
	panel.add_theme_constant_override("margin_bottom", 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	# 卡片标题行：标题 + 朗读按钮
	var head := HBoxContainer.new()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(head)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", font_size(20))
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(title_lbl)

	var idx := _cards.size()

	var speak := Button.new()
	speak.text = "🔊"
	speak.add_theme_font_size_override("font_size", font_size(16))
	speak.custom_minimum_size = Vector2(40, 34)
	speak.pressed.connect(_speak_at.bind(idx))
	head.add_child(speak)

	match t:
		"intro":
			_add_para(root, content, speech_parts)
			if pet: pet.wave()
		"concept":
			_add_para(root, content, speech_parts)
			if str(card.get("animation", "")) == "make_ten_demo":
				_add_para(root, "看演示：把 8 和 2 凑成 10", speech_parts)
				_add_make_ten(root, 8, 2, true)
		"steps":
			var steps: Array = card.get("steps", [])
			for i in range(steps.size()):
				_add_para(root, "%d. %s" % [i + 1, str(steps[i])], speech_parts)
		"example":
			_add_para(root, content, speech_parts)
			if str(card.get("interactive", "")) == "drag_to_make_ten":
				var ab := _parse_add(content)
				if ab[0] > 0:
					_add_make_ten(root, ab[0], ab[1], true)
		"mnemonic":
			_add_para(root, content, speech_parts)

	_cards.append({
		"control": panel,
		"text": "。".join(speech_parts),
	})


func _add_para(parent: Control, text: String, speech_parts: PackedStringArray) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size(16))
	l.add_theme_color_override("font_color", Color(0.2, 0.4, 0.45))
	parent.add_child(l)
	speech_parts.append(text)


func _add_make_ten(parent: Control, big: int, small: int, guided: bool) -> void:
	var ui = preload("res://scripts/make_ten_ui.gd").new()
	ui.setup(big, small, guided)
	ui.completed.connect(_on_make_ten_done)
	ui.ten_reached.connect(_on_ten_reached)
	parent.add_child(ui)


func _ensure_voice_id() -> void:
	if not _voice_id.is_empty():
		return
	var voices := DisplayServer.tts_get_voices()
	if voices.size() == 0:
		toast("没有可用的系统语音")
		return
	for v in voices:
		var name_lc := str(v.get("name", "")).to_lower()
		var lang_lc := str(v.get("language", "")).to_lower()
		if "zh" in name_lc or "cn" in name_lc or "chinese" in name_lc or "中文" in name_lc or \
			"zh" in lang_lc or "cn" in lang_lc or "chinese" in lang_lc or "中文" in lang_lc:
			_voice_id = str(v.get("id", ""))
			return
	_voice_id = str(voices[0].get("id", ""))
	toast("未找到中文语音，已使用默认语音：" + str(voices[0].get("name", "")))


func _on_toggle_auto(btn: CheckButton) -> void:
	_auto_play = btn.button_pressed
	if _auto_play:
		_auto_idx = 0
		_speak_at(_auto_idx)
	else:
		DisplayServer.tts_stop()


func _speak_at(idx: int) -> void:
	if idx < 0 or idx >= _cards.size():
		return
	var c = _cards[idx]
	var sc := _scroll.get_parent()
	if sc is ScrollContainer:
		sc.ensure_control_visible(c["control"])
	var text: String = c["text"]
	if text.is_empty():
		# 空卡片：自动讲模式下直接跳到下一张
		if _auto_play:
			_auto_idx = idx + 1
			if _auto_idx < _cards.size():
				_speak_at(_auto_idx)
			else:
				_auto_play = false
				toast("小精灵讲完啦～")
		return
	# 非自动讲模式下，手动点某张卡片时先停止之前的朗读，避免串到上一张。
	if not _auto_play:
		DisplayServer.tts_stop()
		# 给手动朗读一个可见提示，方便核对文本是否正确。
		var preview := text.left(40)
		if text.length() > 40:
			preview += "…"
		toast("朗读：" + preview)
	DisplayServer.tts_speak(text, _voice_id, 80, 1.0, 0.9, idx, true)
	if pet: pet.wave()
	if _auto_play:
		# 不依赖 tts_utterance_finished 信号（部分 Godot 版本无此信号），
		# 用文本长度估算朗读时长，到时自动朗读下一张。
		var sec := float(text.length()) / 4.0 + 0.8
		get_tree().create_timer(sec).timeout.connect(_on_card_timeout.bind(idx))


func _on_card_timeout(idx: int) -> void:
	if not _auto_play or idx != _auto_idx:
		return
	if _auto_idx < _cards.size() - 1:
		_auto_idx += 1
		_speak_at(_auto_idx)
	else:
		_auto_play = false
		toast("小精灵讲完啦～")


func _on_make_ten_done(_answer: String) -> void:
	if pet: pet.cheer()


func _on_ten_reached() -> void:
	if pet: pet.cheer()


func _finish_button() -> void:
	var b := Button.new()
	b.text = "我听懂啦，下一幕 →"
	b.add_theme_font_size_override("font_size", font_size(16))
	b.custom_minimum_size = Vector2(240, 44) * _font_scale()
	b.pressed.connect(_on_done)
	_scroll.add_child(b)


func _on_done() -> void:
	DisplayServer.tts_stop()
	emit_signal("finished")
