extends HTTPRequest
class_name AIChat

# 定义信号，用于在 AI 回复或发生错误时通知其他节点
signal ai_responded(response_text: String)
signal ai_error(error_msg: String)

# === 配置区：切换使用本地 Ollama 还是云端 API ===
enum APIMode { LOCAL_OLLAMA, CLOUD_API }
var current_mode = APIMode.CLOUD_API

# [1] 本地 Ollama 配置
var ollama_url = "http://localhost:11434/api/generate"
# 请确保这里填写的模型名称和您本地 ollama run 的大模型名称一致
var ollama_model = "deepseek-r1:8b" 

# [2] 云端 API 配置
var cloud_api_url = "https://api.siliconflow.cn/v1/chat/completions"
var cloud_api_key = "sk-wyyidmihgvauxvclkytbpxtggljyilfsnzxbpejtpvcnqjyi"
var cloud_model = "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
# ===============================================

func _ready():
	# 将 HTTP 请求完成的信号连接到回调函数
	request_completed.connect(_on_request_completed)

# 发送提示词给 AI 模型
func send_prompt(prompt: String) -> int:
	var headers = ["Content-Type: application/json"]
	var request_url = ""
	var body = {}
	
	if current_mode == APIMode.LOCAL_OLLAMA:
		request_url = ollama_url
		# 构建本地 Ollama 请求体
		body = {
			"model": ollama_model,
			"prompt": prompt,
			"stream": false, # 禁用流式输出，等待完整回复
			"system": "你是一个在线聊天室的聊天AI。这个聊天室的项目是郑力铭制作的。", # 设定系统提示词
			"options": {
				"temperature": 1.0, # 每次回答的随机性（0.0为严谨，1.0为发散）
				"num_predict": 500 # 限制AI最大回复的字数（Token数）
			}
		}
	else:
		request_url = cloud_api_url
		# 云端 API 需要在头部添加认证 Token
		headers.append("Authorization: Bearer " + cloud_api_key)
		# 构建云端 标准 API 请求体
		body = {
			"model": cloud_model,
			"messages": [
				{"role": "system", "content": "你是一个在线聊天室的聊天AI。这个聊天室的项目是郑力铭制作的。"},
				{"role": "user", "content": prompt}
			],
			"stream": false,
			"temperature": 1.0,
			"max_tokens": 500
		}
	
	# 发起 POST 请求
	var err = request(request_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	
	# 处理请求发送时的内部错误
	if err == ERR_BUSY:
		emit_signal("ai_error", "AI正在思考中，请稍后再问。")
	elif err != OK:
		var err_msg = "无法连接到大模型服务。请检查网络或配置。"
		if current_mode == APIMode.LOCAL_OLLAMA:
			err_msg = "无法连接到本地 Ollama 服务，请检查服务是否已启动并运行在 11434 端口。"
		emit_signal("ai_error", err_msg)
	
	return err

# HTTP 请求完成后的回调函数
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		# 解析响应体内容
		var response_text = body.get_string_from_utf8()
		var json = JSON.parse_string(response_text)
		
		# 提取并发送 AI 的回复文本
		if typeof(json) == TYPE_DICTIONARY:
			# 根据不同的模式提取文本，因为它们返回的 JSON 结构不同
			if current_mode == APIMode.LOCAL_OLLAMA and json.has("response"):
				emit_signal("ai_responded", json["response"])
			elif current_mode == APIMode.CLOUD_API and json.has("choices") and json["choices"].size() > 0:
				var message_content = json["choices"][0]["message"]["content"]
				emit_signal("ai_responded", message_content)
			else:
				emit_signal("ai_error", "解析 AI 响应数据失败：未找到对应的回复字段。")
		else:
			emit_signal("ai_error", "解析 AI 响应数据失败：返回不是正常的字典格式。")
	else:
		# 处理 HTTP 请求本身报错（如 404, 500 等）
		var error_msg = "请求错误状态码: " + str(response_code)
		if body.size() > 0:
			error_msg += " 说明: " + body.get_string_from_utf8()
		emit_signal("ai_error", error_msg)
