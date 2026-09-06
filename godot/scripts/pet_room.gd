extends "res://scripts/base_scene.gd"
##
## 宠物小屋：奖励锚点。展示能量/等级/金币/道具，鼓励继续学习。

func _on_setup() -> void:
	set_title("🏡 宠物小屋")
	back_scene_path = "res://scenes/world_map.tscn"

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	content.add_child(box)

	box.add_child(_mk("⚡ 能量  %d / %d" % [PetState.energy, PetState.max_energy]))
	box.add_child(_mk("⭐ 等级  %d" % PetState.level))
	box.add_child(_mk("🪙 金币  %d" % PetState.coins))
	box.add_child(_mk("🎒 收集到的道具："))
	if PetState.items.is_empty():
		box.add_child(_mk("（还没有，去「练」里赚奖励吧！）"))
	else:
		for it in PetState.items:
			box.add_child(_mk("   • %s  x%d" % [it["name"], int(it["count"])]))

	var cont := Button.new()
	cont.text = "继续学习 →"
	cont.custom_minimum_size = Vector2(220, 44)
	cont.pressed.connect(_on_continue)
	box.add_child(cont)

	# 房间里的宠物（放大欢迎）
	var vp := get_viewport_rect().size
	var big = PetController.spawn(Vector2(vp.x / 2.0 - 30, vp.y - 260))
	big.scale = Vector2(2.4, 2.4)
	big.z_index = 50
	add_child(big)
	big.wave()


# 覆盖 base_scene：小屋用一只放大宠物居中，不要右下角默认宠物
func _place_pet() -> void:
	pass


func _mk(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.15, 0.35, 0.4))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
