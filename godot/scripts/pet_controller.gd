extends Node2D
class_name PetController
##
## Pet — 宠物占位精灵（含动画状态机）
## 在 _ready 中根据 PNG 序列帧构建 SpriteFrames，无需编辑器手填。

enum State { IDLE, WAVE, CHEER, WRONG, THINK }

const FRAMES := {
	"idle": ["pet_idle_0", "pet_idle_1", "pet_idle_2", "pet_idle_3"],
	"wave": ["pet_wave_0", "pet_wave_1", "pet_wave_2", "pet_wave_3"],
	"cheer": ["pet_cheer_0", "pet_cheer_1", "pet_cheer_2", "pet_cheer_3"],
	"wrong": ["pet_wrong_0", "pet_wrong_1"],
	"think": ["pet_think_0", "pet_think_1", "pet_think_2", "pet_think_3"],
}

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var sf := SpriteFrames.new()
	for anim in FRAMES.keys():
		sf.add_animation(anim)
		sf.set_animation_speed(anim, 6.0)
		sf.set_animation_loop(anim, true)
		for f in FRAMES[anim]:
			var tex := load("res://assets/sprites/pet/%s.png" % f)
			if tex != null:
				sf.add_frame(anim, tex)
	sprite.frames = sf
	sprite.play("idle")
	set_stage(PetState.stage_index())


func play_state(s: State) -> void:
	match s:
		State.IDLE: sprite.play("idle")
		State.WAVE: sprite.play("wave")
		State.CHEER: sprite.play("cheer")
		State.WRONG: sprite.play("wrong")
		State.THINK: sprite.play("think")


func idle() -> void: play_state(State.IDLE)
func wave() -> void: play_state(State.WAVE)
func cheer() -> void: play_state(State.CHEER)
func wrong() -> void: play_state(State.WRONG)
func think() -> void: play_state(State.THINK)


const STAGE_TINTS := [
	Color(1, 1, 1, 1),
	Color(1.0, 0.95, 0.75, 1),
	Color(0.8, 1.0, 0.85, 1),
	Color(0.85, 0.9, 1.0, 1),
	Color(1.0, 0.82, 0.92, 1),
	Color(1.0, 1.0, 0.7, 1),
]
const STAGE_SCALES := [1.0, 1.12, 1.25, 1.4, 1.55, 1.75]


## 按进化阶段改色调与缩放
func set_stage(idx: int) -> void:
	idx = clampi(idx, 0, STAGE_TINTS.size() - 1)
	modulate = STAGE_TINTS[idx]
	if sprite != null:
		sprite.scale = Vector2.ONE * STAGE_SCALES[idx]


## 升级时的弹跳特效
func evolve_effect() -> void:
	if sprite == null:
		return
	var base := sprite.scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale", base * 1.25, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", base, 0.25).set_ease(Tween.EASE_IN)
	play_state(State.CHEER)


## 便捷：生成一个已就位的宠物实例
static func spawn(at: Vector2 = Vector2.ZERO) -> Node2D:
	var p = load("res://scenes/pet_scene.tscn").instantiate()
	p.position = at
	return p
