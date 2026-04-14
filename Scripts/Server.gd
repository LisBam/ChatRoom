extends Control

# 服务器端脚本
var peer = ENetMultiplayerPeer.new() # 创建一个 ENet 网络节点实例作为服务器
var PORT = 2310 # 服务器监听的端口
var PYTHON_API_URL = "http://127.0.0.1:5000/api/" # 对应的 Python 后端 API 地址

var connected_users = {} # 存储映射：client_id(客户端ID) : username(用户名)
var user_clients = {}    # 存储映射：username(用户名) : client_id(客户端ID)

func _ready():
    peer.create_server(PORT) # 启动服务器，监听指定端口
    multiplayer.multiplayer_peer = peer # 设置当前网络节点为服务器节点
    multiplayer.peer_connected.connect(_on_peer_connected) # 连接客户端接入的信号
    multiplayer.peer_disconnected.connect(_on_peer_disconnected) # 连接客户端断开的信号
    print("服务器已启动，监听端口：", PORT)

# 辅助函数：发送异步 HTTP 请求给 Python 后端
func _send_http_request(endpoint: String, payload: Dictionary) -> Dictionary:
    var http_request = HTTPRequest.new() # 创建 HTTP 请求节点
    add_child(http_request) # 添加到场景树中
    var json = JSON.stringify(payload) # 将字典载荷转换为 JSON 字符串
    var headers = ["Content-Type: application/json"] # 设置请求头
    # 向指定端点发起 POST 请求
    http_request.request(PYTHON_API_URL + endpoint, headers, HTTPClient.METHOD_POST, json)
    
    var response = await http_request.request_completed # 等待请求完成
    var result = response[0]
    var response_code = response[1]
    var headers_resp = response[2]
    var body = response[3]
    
    http_request.queue_free() # 释放 HTTP 请求节点
    
    if response_code == 200:
        # 如果返回 200，则解析返回的 JSON 数据
        var json_response = JSON.parse_string(body.get_string_from_utf8())
        if typeof(json_response) == TYPE_DICTIONARY:
            return json_response
    
    return {"success": false, "msg": "HTTP request failed"} # 如果失败返回默认错误信息


# 当有客户端连接时回调
func _on_peer_connected(id):
    print("客户端已连接: ", id)

# 当有客户端断开连接时回调
func _on_peer_disconnected(id):
    if connected_users.has(id):
        # 清除断开连接的用户在字典中的记录
        var uname = connected_users[id]
        user_clients.erase(uname)
        connected_users.erase(id)
    print("客户端已断开连接: ", id)

# 处理客户端的注册请求
@rpc("any_peer", "call_remote")
func register_user(username, password, email):
    var client_id = multiplayer.get_remote_sender_id() # 获取发送请求的客户端 ID
    # 向后台发送注册的 HTTP 请求
    var response = await _send_http_request("register", {"username": username, "password": password, "email": email})
    
    if response.get("success", false):
        # 成功，告诉该客户端并发送认证响应
        rpc_id(client_id, "auth_response", true, "注册成功")
    else:
        # 失败，发送失败信息
        var msg = response.get("msg", "注册失败")
        rpc_id(client_id, "auth_response", false, msg)

# 处理客户端的登录请求
@rpc("any_peer", "call_remote")
func login_user(username, password):
    var client_id = multiplayer.get_remote_sender_id() # 获取发送请求的客户端 ID
    # 向后台发送登录的 HTTP 请求
    var response = await _send_http_request("login", {"username": username, "password": password})
    
    if response.get("success", false):
        # 登录成功，把玩家添加到在线列表
        connected_users[client_id] = username
        user_clients[username] = client_id
        rpc_id(client_id, "auth_response", true, "登录成功") # 通知客户端登录成功
        
        # 向后台请求聊天记录
        var history_response = await _send_http_request("get_history", {"username": username})
        if history_response.get("success", false):
            var history = history_response.get("history", [])
            for msg in history:
                # 判断是否是私聊
                var is_private = msg.receiver != ""
                # 把 sender 和 receiver 都传过去，方便客户端正确归类历史信息
                rpc_id(client_id, "receive_message", msg.sender, msg.receiver, msg.content, msg.type, is_private)
    else:
        # 登录失败，通知客户端
        rpc_id(client_id, "auth_response", false, response.get("msg", "登录失败"))

# 处理客户端的发送消息请求
@rpc("any_peer", "call_remote")
func send_message(content, type, target):
    var sender_id = multiplayer.get_remote_sender_id() # 获取发送请求的客户端 ID
    var sender_name = connected_users.get(sender_id, "Unknown") # 获取用户名
    
    # 将消息保存到后台数据库，无需等待响应
    _send_http_request("save_message", {"sender": sender_name, "receiver": target, "content": content, "type": type})
    rpc_id(sender_id, "update_status", "delivered") # 告诉发送者消息已投递
    
    if target == "": # 如果目标为空，视为公共消息（广播）
        for client in connected_users.keys():
            if client != sender_id: # 不要发给自己
                rpc_id(client, "receive_message", sender_name, "", content, type, false)
    else: # 否则是私下发送（私聊）
        if user_clients.has(target):
            # 发送给指定的用户
            rpc_id(user_clients[target], "receive_message", sender_name, target, content, type, true)
            rpc_id(sender_id, "update_status", "read") # 假设发过去以后算作已读

# --- RPC STUBS FOR CLIENT ---
# 这些是客户端接收函数的存根，为了让服务器通过 rpc_id 能够查找到相应的方法名
@rpc("any_peer", "call_remote") func auth_response(_success, _msg): pass # 认证响应
@rpc("any_peer", "call_remote") func receive_message(_sender, _receiver, _content, _type, _is_private): pass # 接收消息
@rpc("any_peer", "call_remote") func update_status(_status): pass # 更新发送状态
