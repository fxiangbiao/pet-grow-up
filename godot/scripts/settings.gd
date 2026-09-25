extends Node
##
## Settings — 全局设置（autoload 单例）：音量 / 震动 / 气泡
## 持久化到 user://settings.cfg，启动即加载并应用到音频总线。
## 总线：0=Master（主音量）、Sfx（音效/配音）。

const SAVE_PATH := "user://settings.cfg"
const SFX_BUS := "Sfx"

var master_volume: float = 0.85
var sfx_volume: float = 0.85
var shake_enabled := true
var bubble_enabled := true


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply_audio()


# ===================== 音频总线 =====================

func _ensure_buses() -> void:
	# 为音效建立独立总线（若不存在）
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, SFX_BUS)


func sfx_bus_index() -> int:
	_ensure_buses()
	return AudioServer.get_bus_index(SFX_BUS)


func apply_audio() -> void:
	var master_db := _to_db(master_volume)
	AudioServer.set_bus_volume_db(0, master_db)
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	var s := sfx_bus_index()
	if s != -1:
		AudioServer.set_bus_volume_db(s, _to_db(sfx_volume))
		AudioServer.set_bus_mute(s, sfx_volume <= 0.001)


static func _to_db(v: float) -> float:
	var c := clampf(v, 0.0, 1.0)
	if c <= 0.001:
		return -80.0
	return linear_to_db(c * c)


# ===================== 持久化 =====================

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	shake_enabled = bool(cfg.get_value("gameplay", "shake", shake_enabled))
	bubble_enabled = bool(cfg.get_value("gameplay", "bubble", bubble_enabled))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("gameplay", "shake", shake_enabled)
	cfg.set_value("gameplay", "bubble", bubble_enabled)
	cfg.save(SAVE_PATH)


# ===================== 快捷修改并生效 =====================

func set_master(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_sfx(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_shake(on: bool) -> void:
	shake_enabled = on
	save_settings()


func set_bubble(on: bool) -> void:
	bubble_enabled = on
	save_settings()
