extends "res://scripts/act_base.gd"
##
## 学（Learn）：孩子自己动手，宠物实时鼓励，不计分

var _done := false


func _build() -> void:
	add_heading("🤝 学：你来试一试")
	add_paragraph("小精灵在旁边陪着你，慢慢来，做错了也没关系～")

	var ab := _find_example()
	_add_make_ten(ab[0], ab[1])

	_finish_button()


func _find_example() -> Array:
	if ctx.has("teaching") and typeof(ctx["teaching"]) == TYPE_DICTIONARY:
		var cards: Array = ctx["teaching"].get("cards", [])
		for card in cards:
			if str(card.get("interactive", "")) == "drag_to_make_ten":
				var ab := _parse_add(str(card.get("content", "")))
				if ab[0] > 0:
					return ab
	return [8, 5]


func _add_make_ten(big: int, small: int) -> void:
	var ui = preload("res://scripts/make_ten_ui.gd").new()
	ui.setup(big, small, true)
	ui.ten_reached.connect(_on_ten_reached)
	ui.completed.connect(_on_make_ten_done)
	_scroll.add_child(ui)
	add_paragraph("（小提示：先看大数 %d，想想要补几个才到 10）" % big)


func _on_ten_reached() -> void:
	if pet: pet.cheer()


func _on_make_ten_done(_answer: String) -> void:
	if pet: pet.cheer()
	if not _done:
		_done = true
		toast("你真棒！学会凑十法啦～")


func _finish_button() -> void:
	var b := Button.new()
	b.text = "练一练，下一幕 →"
	b.custom_minimum_size = Vector2(240, 44)
	b.pressed.connect(_on_done)
	_scroll.add_child(b)


func _on_done() -> void:
	emit_signal("finished")
