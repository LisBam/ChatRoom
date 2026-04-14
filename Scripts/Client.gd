extends Control

# 客户端脚本，用于处理登录、注册和聊天界面
var peer = ENetMultiplayerPeer.new() # 创建一个 ENet 网络节点实例
var PORT = 8080 # 服务器端口
var IP_ADDRESS = "127.0.0.1" # 服务器的 IP 地址

# 定义聊天模式枚举：公开和私聊
enum ChatMode { PUBLIC, PRIVATE }
var current_mode = ChatMode.PUBLIC # 当前的聊天模式
var current_receiver = "" # 当前私聊的接收者
var username = "" # 当前用户的用户名

# 获取 UI 节点的引用
@onready var login_panel = $LoginPanel # 登录面板
@onready var chat_panel = $ChatPanel # 聊天面板
@onready var chat_history = $ChatPanel/VBoxContainer/HistoryText # 聊天记录文本框
@onready var message_input = $ChatPanel/VBoxContainer/HBoxContainer/MessageInput # 消息输入框
@onready var target_input = $ChatPanel/VBoxContainer/HBoxContainer/TargetInput # 目标用户输入框（用于私聊）
@onready var usr_input = $LoginPanel/VBox/UserInput # 用户名输入框
@onready var pwd_input = $LoginPanel/VBox/PwdInput # 密码输入框
@onready var email_input = $LoginPanel/VBox/EmailInput # 邮箱输入框
@onready var status_label = $LoginPanel/VBox/Label # 状态标签（显示登录/连接状态）

func _ready():
    # 初始状态隐藏聊天面板，显示登录面板
    chat_panel.visible = false
    login_panel.visible = true
    
    # 客户端一打开就连接 Godot 服务器
    var err = peer.create_client(IP_ADDRESS, PORT)
    if err == OK:
        multiplayer.multiplayer_peer = peer # 将当前的网络节点设置为刚才创建的客户端节点
    else:
        status_label.text = "Error: Cannot start ENet client" # 无法启动客户端时报错
        
    # 连接网络信号以响应连接成功和断开事件
    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(_on_connection_error)
    multiplayer.server_disconnected.connect(_on_connection_error)
    
    # 绑定回车键发送消息
    message_input.text_submitted.connect(_on_message_input_text_submitted)

# 连接服务器成功时的回调
func _on_connected():
    status_label.text = "Connected to Server. Please Login."

# 连接服务器失败或断开连接时的回调
func _on_connection_error():
    status_label.text = "Lost connection to Server!"

# 点击注册按钮时的回调
func _on_register_pressed():
    # 检查是否已连接到服务器
    if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        status_label.text = "Error: Not connected to Godot Server!"
        return
    
    status_label.text = "Registering..." # 显示注册中
    # 发送注册请求到服务器（ID 为 1 代表服务器）
    rpc_id(1, "register_user", usr_input.text, pwd_input.text, email_input.text)

# 点击登录按钮时的回调
func _on_login_pressed():
    # 检查是否已连接到服务器
    if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        status_label.text = "Error: Not connected to Godot Server!"
        return
        
    status_label.text = "Logging in..."  # 显示登录中
    # 发送登录请求到服务器
    rpc_id(1, "login_user", usr_input.text, pwd_input.text)
    username = usr_input.text # 保存当前尝试登录的用户名

# 接收服务器发回的认证响应
@rpc("any_peer", "call_remote")
func auth_response(success: bool, msg: String):
    print(msg)
    if success:
        # 登录成功，隐藏登录面板，显示聊天面板
        login_panel.visible = false
        chat_panel.visible = true
    else:
        # 登录失败，显示错误信息
        status_label.text = "Failed: " + msg

# 点击发送消息按钮时的回调
func _on_send_pressed():
    var type = "text" # 消息类型为普通文本
    var content = message_input.text # 获取输入的消息内容
    var target = target_input.text # 获取输入的目标用户名
    
    # 消息为空则不发送
    if content.strip_edges() == "":
        return
    
    # 如果目标为空，则发送公开消息，否则发送私聊消息
    if target == "":
        current_mode = ChatMode.PUBLIC
        rpc_id(1, "send_message", content, type, "") # 向服务器发送广播消息
    else:
        current_mode = ChatMode.PRIVATE
        rpc_id(1, "send_message", content, type, target) # 向服务器发送私聊消息请求
    
    # 在本地聊天记录中追加自己发送的消息
    chat_history.text += "[You]: " + content + "\n"
    message_input.text = "" # 清空输入框

# 输入框按下回车时的回调
func _on_message_input_text_submitted(_new_text: String):
    _on_send_pressed()

# 接收别人发来的消息
@rpc("any_peer", "call_remote")
func receive_message(sender: String, content: String, type: String, is_private: bool):
    # 根据是否是私聊，添加不同的前缀
    var prefix = "[Private from " + sender + "]: " if is_private else "[" + sender + "]: "
    # 把消息追加到聊天记录文本里
    chat_history.text += prefix + content + "\n"

# 接收来自服务器的消息状态更新（例如：delivered）
@rpc("any_peer", "call_remote")
func update_status(status: String):
    pass

# --- RPC STUBS FOR SERVER ---
# 这些是服务器端接收函数的存根（Stub），为了让客户端通过 rpc_id 能够查找到相应的方法名
@rpc("any_peer", "call_remote") func register_user(_u, _p, _e): pass # 注册方法
@rpc("any_peer", "call_remote") func login_user(_u, _p): pass # 登录方法
@rpc("any_peer", "call_remote") func send_message(_c, _t, _tg): pass # 发送消息方法
