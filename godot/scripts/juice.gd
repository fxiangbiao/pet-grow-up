extends Node
class_name Juice
##
## Juice — 即时反馈工具（粒子爆发 / 文字弹出 / 一次性音效）
## 全部以 parent 节点为挂载点；用 class_name 暴露为全局名，无需注册 autoload。

const STAR := preload("res://assets/sprites/fx/star.png")
const CORRECT := preload("res://assets/audio/correct.wav")
const WRONG := preload("res://assets/audio/wrong.wav")
const LEVELUP := preload("res://assets/audio/levelup.wav")


## 在 parent 本地坐标 at 处喷一圈星星
static func burst(parent: Node, at: Vector2, count: int = 12, color: Color = Color(1, 0.84, 0.0)) -> void:
	if parent == null:
		return
	for i in range(count):
		var s := Sprite2D.new()
		s.texture = STAR
		s.modulate = color
		s.position = at
		s.scale = Vector2(0.5, 0.5)
		parent.add_child(s)
		var ang := float(i) / float(count) * TAU
		var dist := 60.0 + randf() * 50.0
		var target := at + Vector2(cos(ang), sin(ang)) * dist
		var tw := parent.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", target, 0.6).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector2(0.1, 0.1), 0.6).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "modulate:a", 0.0, 0.6)
		tw.tween_callback(s.queue_free)


## 在 parent 本地坐标 at 处弹出一个会升腾消失的文字
static func popup_text(parent: Node, at: Vector2, text: String, color: Color = Color(1, 0.7, 0.1)) -> void:
	if parent == null:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = at - Vector2(50, 10)
	parent.add_child(l)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position", at - Vector2(50, 70), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


static func sfx_correct(parent: Node) -> void:
	_play(parent, CORRECT, -8.0, true)


static func sfx_wrong(parent: Node) -> void:
	_play(parent, WRONG, -12.0, false)


static func sfx_levelup(parent: Node) -> void:
	_play(parent, LEVELUP, -6.0, true)


## 轻微震屏（可被设置里的“震动”关闭）；作用于 Control 根节点
static func shake(ctrl: Control, strength: float = 6.0, dur: float = 0.32) -> void:
	if ctrl == null or not ctrl.is_inside_tree():
		return
	if not Settings.shake_enabled:
		return
	var base: Vector2 = ctrl.position
	var step := maxf(dur / 6.0, 0.02)
	var tw := ctrl.create_tween()
	var sign := 1.0
	for i in range(6):
		var off := Vector2(strength * sign * (1.0 - float(i) / 8.0), 0.0)
		tw.tween_property(ctrl, "position", base + off, step)
		sign = -sign
	tw.tween_property(ctrl, "position", base, step * 1.4)


static func _play(parent: Node, stream: AudioStream, vol: float, random_pitch: bool = false) -> void:
	if parent == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = vol + (randf_range(-1.2, 1.2) if random_pitch else 0.0)
	if random_pitch:
		p.pitch_scale = randf_range(0.92, 1.12)
	# 音效走独立 Sfx 总线（由 Settings autoload 创建并控制音量）
	var tree := parent.get_tree()
	if tree != null and tree.root != null and tree.root.has_node("Settings"):
		p.bus = "Sfx"
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
