extends Node
##
## Demo — 离线兜底数据（后端未启动时也能打开即玩）
## 内嵌「凑十法」教学卡片与本地题目生成，模拟真实后端返回结构。

const MAKE_TEN_TEACHING := {
	"cards": [
		{"id": 1, "type": "intro", "title": "小精灵的苹果园",
		 "content": "小精灵去果园摘苹果，树上有8个红苹果，地上又掉了2个青苹果。一共有几个苹果呢？",
		 "spriteAction": "wave", "illustration": "apple_tree"},
		{"id": 2, "type": "concept", "title": "什么是凑十法",
		 "content": "凑十法就是：看到大数8，想一想还差几个能凑成10。8差2就是10！所以先把2补给8，变成10，再加剩下的。",
		 "animation": "make_ten_demo"},
		{"id": 3, "type": "steps", "title": "凑十法四步走",
		 "steps": ["看大数：看到8，知道8接近10", "拆小数：把另一个数拆开",
		 "凑成十：拿出2给8，凑成10", "加剩余：剩下的加起来"]},
		{"id": 4, "type": "example", "title": "动手试试",
		 "content": "8 + 5 = ?", "interactive": "drag_to_make_ten"},
		{"id": 5, "type": "mnemonic", "title": "凑十歌",
		 "content": "一九一九好朋友，\n二八二八手拉手，\n三七三七真亲密，\n四六四六一起走，\n五五凑成一双手。"}
	]
}

var _demo_index := 0
## 当前选中的学程节点（world_map 写入，learning_loop 读取）
var current_node: Dictionary = {}


## 离线教学卡片（按 node_key 兜底）
func teaching_for(node_key: String) -> Variant:
	if node_key == "math_make_ten":
		return MAKE_TEN_TEACHING
	return {"cards": [{"id": 1, "type": "concept", "title": node_key, "content": "（离线占位内容）"}]}


## 离线题目：随机生成一道凑十法题，返回类 QuestionDTO 字典
func next_demo_question(session_id: int, answered: int, total: int) -> Dictionary:
	var a := 7 + (_demo_index % 3)      # 7,8,9
	var b := 4 + ((_demo_index / 3) % 4) # 4..7
	_demo_index += 1
	return {
		"sessionId": session_id,
		"questionId": 1000 + _demo_index,
		"questionType": "make_ten",
		"questionText": "%d + %d = ?" % [a, b],
		"options": "",
		"points": 10,
		"totalQuestions": total,
		"answeredCount": answered,
	}


## 离线判分：返回类 AnswerResultDTO 字典
func demo_answer(session_id: int, q: Dictionary, answer: String, answered: int, total: int) -> Dictionary:
	var qt: String = str(q["questionText"])
	var parts: PackedStringArray = qt.replace(" ", "").split("+")
	var a := int(parts[0]); var b := int(parts[1].replace("=?", "").replace("=", ""))
	var correct := a + b
	var is_ok := (str(correct) == answer.strip_edges())
	return {
		"isCorrect": is_ok,
		"correctAnswer": str(correct),
		"explanation": "看大数 %d，拆小数 %d：先拿 %d 凑成10，再加剩下的 %d，得 %d。" % [a, b, 10 - a, b - (10 - a), correct],
		"pointsEarned": 10 if is_ok else 0,
		"isSessionComplete": answered >= total,
		"isLastQuestion": answered >= total,
		"nextQuestion": null,
		"sceneRewardItem": "apple" if is_ok else "",
		"sceneRewardCount": 1 if is_ok else 0,
	}


## 离线变式：在原题基础上换一个数字，返回类 QuestionDTO 字典
func demo_variant(q: Dictionary) -> Dictionary:
	var qt: String = str(q["questionText"])
	var parts: PackedStringArray = qt.replace(" ", "").split("+")
	var a := int(parts[0]); var b := int(parts[1].replace("=?", "").replace("=", ""))
	var na := mini(a + 1, 9)
	return {
		"sessionId": q.get("sessionId", 1),
		"questionId": int(q.get("questionId", 1000)) + 100,
		"questionType": "make_ten",
		"questionText": "%d + %d = ?" % [na, b],
		"options": "",
		"points": 10,
		"totalQuestions": q.get("totalQuestions", 5),
		"answeredCount": 0,
	}
