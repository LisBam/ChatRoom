extends HTTPRequest
class_name AIChat

## 云端 AI 密钥的环境变量名；默认从启动 Godot 进程的本机环境读取，不应写入共享场景。
const CLOUD_API_KEY_ENVIRONMENT_VARIABLE: String = "CHATROOM_SILICONFLOW_API_KEY"

## 云端模式缺少密钥时的提示；该检查不影响本地 Ollama 模式。
const MISSING_CLOUD_API_KEY_MESSAGE: String = "未配置云端 AI 密钥，请设置环境变量 CHATROOM_SILICONFLOW_API_KEY 后重启程序，或在本机检查器覆盖。"


signal ai_responded(response_text: String)
signal ai_error(error_msg: String)

enum APIMode { LOCAL_OLLAMA, CLOUD_API }
var current_mode = APIMode.CLOUD_API

var ollama_url = "http://localhost:11434/api/generate"
var ollama_model = "deepseek-r1:8b" 

var cloud_api_url = "https://api.siliconflow.cn/v1/chat/completions"
## 云端认证密钥；默认读取本机环境，允许检查器调试覆盖；保存覆盖值会写入场景，因此真实密钥不能提交。
@export var cloud_api_key: String = OS.get_environment(CLOUD_API_KEY_ENVIRONMENT_VARIABLE)
var cloud_model = "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"

func _ready():
	# 将 HTTP 请求完成的信号连接到回调函数
	request_completed.connect(_on_request_completed)

func send_prompt(prompt: String) -> int:
	var headers = ["Content-Type: application/json"]
	var request_url = ""
	var body = {}
	
	if current_mode == APIMode.LOCAL_OLLAMA:
		request_url = ollama_url
		body = {
			"model": ollama_model,
			"prompt": prompt,
			"stream": false,
			"system": "你是一个在线聊天室的聊天AI。这个聊天室的项目是本项目开发者制作的。", # 设定系统提示词
			"options": {
				"temperature": 1.0,
				"num_predict": 500
			}
		}
	else:
		# 在发起云端请求前校验本机配置，避免携带空认证头访问服务。
		if cloud_api_key.strip_edges().is_empty():
			emit_signal("ai_error", MISSING_CLOUD_API_KEY_MESSAGE)
			return ERR_UNCONFIGURED
		request_url = cloud_api_url
		# 云端 API 需要在头部添加认证 Token
		headers.append("Authorization: Bearer " + cloud_api_key)
		body = {
			"model": cloud_model,
			"messages": [
				{"role": "system", "content": "你是一个在线聊天室的聊天AI。这个聊天室的项目是本项目开发者制作的。"},
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
