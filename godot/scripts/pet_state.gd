extends Node
##
## PetState — 宠物养成状态（autoload 单例）
## 缓存能量/等级/金币/道具，并持久化到 user://pet_state.json

var energy: int = 100
var max_energy: int = 120
var level: int = 1
var exp: int = 0
var coins: int = 0
var items: Array = []  # [{ "id": int, "name": String, "count": int }]
var pet_name: String = "小精灵"

const STAGE_NAMES := ["蛋", "幼崽", "童年", "少年", "成年", "传说"]

const SAVE_PATH := "user://pet_state.json"


func set_energy(v: int) -> void:
	energy = clampi(v, 0, max_energy)
	save()


func add_energy(v: int) -> void:
	set_energy(energy + v)


func add_coins(v: int) -> void:
	coins += v
	save()


func add_item(id: int, name: String, count: int = 1) -> void:
	for it in items:
		if it["id"] == id:
			it["count"] += count
			save()
			return
	items.append({"id": id, "name": name, "count": count})
	save()


func set_pet_name(n: String) -> void:
	pet_name = n
	save()


## 升到下一级所需经验
func exp_needed(lv: int) -> int:
	return 40 + lv * 20


## 等级对应的进化阶段索引
func stage_for_level(lv: int) -> int:
	if lv >= 15: return 5
	if lv >= 11: return 4
	if lv >= 8: return 3
	if lv >= 5: return 2
	if lv >= 3: return 1
	return 0


func stage_index() -> int:
	return stage_for_level(level)


func stage_name() -> String:
	return STAGE_NAMES[stage_index()]


## 加经验，返回 { leveled_up, stage_changed, new_stage }
func add_exp(amount: int) -> Dictionary:
	var before_stage := stage_index()
	exp += maxi(amount, 0)
	var leveled := false
	while exp >= exp_needed(level):
		exp -= exp_needed(level)
		level += 1
		leveled = true
	var after_stage := stage_index()
	save()
	return {"leveled_up": leveled, "stage_changed": after_stage != before_stage, "new_stage": after_stage}


func save() -> void:
	var data := {
		"energy": energy,
		"max_energy": max_energy,
		"level": level,
		"exp": exp,
		"coins": coins,
		"items": items,
		"pet_name": pet_name,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	energy = int(parsed.get("energy", energy))
	max_energy = int(parsed.get("max_energy", max_energy))
	level = int(parsed.get("level", level))
	exp = int(parsed.get("exp", exp))
	coins = int(parsed.get("coins", coins))
	items = parsed.get("items", items)
	pet_name = str(parsed.get("pet_name", pet_name))
