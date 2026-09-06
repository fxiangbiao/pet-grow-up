extends Node
##
## ApiClient — 后端接口封装（autoload 单例）
## 所有响应都被 ApiResponse<T> 包裹：{ code, message, data, timestamp }
## 本脚本统一解包 data 字段后回调 on_done。
##
## 后端地址默认 http://127.0.0.1:8080，可用 set_base_url 覆盖。

const DEFAULT_BASE_URL := "http://127.0.0.1:8080"

var base_url := DEFAULT_BASE_URL
var token: String = ""
var user_id: int = -1
var username: String = ""

# ---- 信号 ----
signal login_succeeded
signal login_failed(message: String)
signal request_failed(message: String)


func set_base_url(url: String) -> void:
	base_url = url


## 启动时读取环境变量覆盖后端地址，便于在不同部署拓扑下切换：
##  - 原生桌面（Godot 跑在宿主机）：不设置则用默认 127.0.0.1:8080 直连宿主 Docker 后端
##  - Godot 也跑在 Docker 容器内：设 PETGROWUP_API_URL=http://backend:8080（容器网络服务名）
func _ready() -> void:
	var env := OS.get_environment("PETGROWUP_API_URL")
	if env != "":
		base_url = env


func _auth_headers() -> PackedStringArray:
	var h: PackedStringArray = ["Content-Type: application/json"]
	if token != "":
		h.append("Authorization: Bearer " + token)
	return h


## 统一请求封装。on_done 收到的是 data 字段（已解包）。
func _request(method: int, path: String, body_dict: Variant, on_done: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_response.bind(http, on_done))
	var url := base_url + path
	var body := ""
	if body_dict != null:
		body = JSON.stringify(body_dict)
	var err := http.request(url, _auth_headers(), method, body)
	if err != OK:
		http.queue_free()
		request_failed.emit("请求发送失败 (HTTP 初始化错误)")


func _on_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, on_done: Callable) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("网络错误，无法连接后端 (%d)" % result)
		return
	if response_code < 200 or response_code >= 300:
		request_failed.emit("后端返回错误码 %d" % response_code)
		return
	var text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("响应不是合法 JSON")
		return
	var payload: Variant = parsed
	if parsed.has("data"):
		payload = parsed["data"]
	on_done.call(payload)


# ===================== 认证 =====================

func login(user: String, pwd: String) -> void:
	_request(HTTPClient.METHOD_POST, "/api/v1/auth/login",
		{"username": user, "password": pwd}, _on_login_done)


func _on_login_done(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		login_failed.emit("登录响应格式异常")
		return
	if not data.has("accessToken"):
		login_failed.emit("未返回 token")
		return
	token = data["accessToken"]
	if data.has("user") and typeof(data["user"]) == TYPE_DICTIONARY:
		var u: Dictionary = data["user"]
		if u.has("id"):
			user_id = int(u["id"])
		if u.has("username"):
			username = str(u["username"])
		if u.has("currentEnergy"):
			PetState.set_energy(int(u["currentEnergy"]))
	login_succeeded.emit()


func logout() -> void:
	token = ""
	user_id = -1
	username = ""


# ===================== 学程导航 =====================

func get_subjects(on_done: Callable) -> void:
	_request(HTTPClient.METHOD_GET, "/api/v1/study/subjects", null, on_done)


func get_world_map(subject: String, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_GET, "/api/v1/study/worlds/%s" % subject, null, on_done)


# ===================== 教 =====================

func get_teaching(node_id: int, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_GET, "/api/v1/study/nodes/%d/teaching" % node_id, null, on_done)


# ===================== 练 =====================

## 开始一次练习会话，返回首题 QuestionDTO
func start_session(subject: String, session_type: String, difficulty: int, node_id: int, on_done: Callable) -> void:
	var body := {
		"subject": subject,
		"sessionType": session_type,
		"difficultyLevel": difficulty,
		"knowledgeNodeId": node_id,
	}
	_request(HTTPClient.METHOD_POST, "/api/v1/exploration/sessions/start", body, on_done)


## 提交答案，返回 AnswerResultDTO（含 nextQuestion / sceneRewardItem）
## 注意：后端 SubmitAnswerRequest 要求 body 内也必须带 sessionId（@NotNull）
func submit_answer(session_id: int, question_id: int, answer: String, time_spent: int, on_done: Callable) -> void:
	var body := {
		"sessionId": session_id,
		"questionId": question_id,
		"answer": answer,
		"timeSpent": time_spent,
	}
	_request(HTTPClient.METHOD_POST, "/api/v1/exploration/sessions/%d/submit" % session_id, body, on_done)


# ===================== 拓 =====================

func generate_variant(node_id: int, original_question_id: int, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_GET,
		"/api/v1/study/nodes/%d/generate-variant?originalQuestionId=%d" % [node_id, original_question_id],
		null, on_done)


func explain(node_id: int, text: String, on_done: Callable) -> void:
	_request(HTTPClient.METHOD_POST, "/api/v1/study/nodes/%d/explain" % node_id,
		{"text": text}, on_done)
