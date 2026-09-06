extends "res://scripts/base_scene.gd"
##
## LearningLoop — 教/学/练/拓 四幕学习循环编排器

var _node: Dictionary
var _teaching: Variant = null
var _stage: Control
var _progress: Label
var _acts := ["教", "学", "练", "拓"]
var _act_paths := [
	"res://scenes/teach/teach_scene.tscn",
	"res://scenes/learn/learn_scene.tscn",
	"res://scenes/practice/practice_scene.tscn",
	"res://scenes/extend/extend_scene.tscn",
]
var _idx := 0
var _current_act: Node = null


func _on_setup() -> void:
	_node = Demo.current_node
	set_title("学习：" + str(_node.get("key", "节点")))
	back_scene_path = "res://scenes/world_map.tscn"
	_build_stage()
	_load_teaching()


# 覆盖 base_scene：四幕由 act_base 自己放置宠物，避免重复
func _place_pet() -> void:
	pass


func _build_stage() -> void:
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.offset_top = 92
	_stage.offset_bottom = -66
	add_child(_stage)

	_progress = Label.new()
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_progress.offset_top = 58
	_progress.offset_bottom = 86
	_progress.add_theme_font_size_override("font_size", 18)
	_progress.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	add_child(_progress)

	var next := Button.new()
	next.text = "下一幕 →"
	next.custom_minimum_size = Vector2(120, 36)
	next.anchor_left = 0.5; next.anchor_right = 0.5; next.anchor_top = 1.0; next.anchor_bottom = 1.0
	next.offset_left = -60; next.offset_right = 60; next.offset_top = -50; next.offset_bottom = -14
	next.pressed.connect(_on_advance)
	add_child(next)


func _load_teaching() -> void:
	if ApiClient.token != "" and int(_node.get("id", -1)) > 0:
		ApiClient.get_teaching(int(_node["id"]), _on_teaching)
		ApiClient.request_failed.connect(_on_req_fail)
	else:
		_teaching = Demo.teaching_for(str(_node.get("key", "")))
		_start_act(0)


func _on_teaching(data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("cards"):
		_teaching = data
	else:
		_teaching = Demo.teaching_for(str(_node.get("key", "")))
	_start_act(0)


func _start_act(i: int) -> void:
	_idx = i
	if _current_act != null:
		_current_act.queue_free()
		_current_act = null
	var path: String = _act_paths[i]
	var scene: PackedScene = load(path)
	_current_act = scene.instantiate()
	_stage.add_child(_current_act)
	var ctx := {
		"node_id": int(_node.get("id", -1)),
		"node_key": str(_node.get("key", "")),
		"subject": str(_node.get("subject", "math")),
		"teaching": _teaching,
		"loop": self,
	}
	if _current_act.has_method("setup"):
		_current_act.setup(ctx)
	if _current_act.has_signal("finished"):
		_current_act.finished.connect(_on_act_finished)
	_update_progress()


func _update_progress() -> void:
	var parts: PackedStringArray = []
	for k in range(_acts.size()):
		if k == _idx:
			parts.append("[ %s ]" % _acts[k])
		else:
			parts.append(_acts[k])
	_progress.text = " → ".join(parts)


func _on_advance() -> void:
	_on_act_finished()


func _on_act_finished() -> void:
	var r := PetState.add_exp(12)
	if r.leveled_up and _current_act != null:
		var p = _current_act.get("pet")
		if p != null and p.has_method("set_stage"):
			p.set_stage(r["new_stage"])
			if p.has_method("evolve_effect"):
				p.evolve_effect()
	refresh_hud()
	if _idx < _acts.size() - 1:
		_start_act(_idx + 1)
	else:
		toast("四幕完成！宠物获得成长，去看看奖励吧~")
		get_tree().change_scene_to_file("res://scenes/pet_room.tscn")


func _on_req_fail(msg: String) -> void:
	if _teaching == null:
		_teaching = Demo.teaching_for(str(_node.get("key", "")))
		_start_act(0)
	else:
		toast(msg)
