extends Control

# 客户端脚本，用于处理登录、注册和聊天界面
var peer = ENetMultiplayerPeer.new() # 创建一个 ENet 网络节点实例
var PORT = 2310 # 服务器端口
var IP_ADDRESS = "127.0.0.1" # 服务器的 IP 地址

# 定义聊天模式枚举：公开和私聊
enum ChatMode { PUBLIC, PRIVATE }
var current_mode = ChatMode.PUBLIC # 当前的聊天模式
var current_receiver = "" # 当前私聊的接收者
var username = "" # 当前用户的用户名
var ai_chat_node # 用于和本地 AI 通信的重要节点
var online_count = 0 # 在线人数

# 存储各种聊天历史，空字符串代表大厅
var chat_histories = {"": ""} 
var unread_channels = {} # 记录未读频道的字典，用于闪烁提示
var contact_update_times = {"": 0.0, "AI助手": 0.0} # 记录频道最后更新时间

# 获取 UI 节点的引用
@onready var login_panel = $LoginPanel # 登录面板
@onready var chat_panel = $ChatPanel # 聊天面板
@onready var contact_list = $ChatPanel/ChatLayout/Sidebar/ContactList # 联系人列表
@onready var new_contact_input = $ChatPanel/ChatLayout/Sidebar/AddContactBox/NewContactInput # 新联系人输入框
@onready var current_chat_label = $ChatPanel/ChatLayout/ChatArea/CurrentChatLabel # 当前聊天频道名称
@onready var chat_history = $ChatPanel/ChatLayout/ChatArea/HistoryText # 聊天记录文本框
@onready var message_input = $ChatPanel/ChatLayout/ChatArea/InputLayout/MessageInput # 消息输入框
@onready var send_btn = $ChatPanel/ChatLayout/ChatArea/InputLayout/SendBtn # 发送按钮
@onready var usr_input = $LoginPanel/VBox/UserInput # 用户名输入框
@onready var pwd_input = $LoginPanel/VBox/PwdInput # 密码输入框
@onready var email_input = $LoginPanel/VBox/EmailInput # 邮箱输入框
@onready var status_label = $LoginPanel/VBox/Label # 状态标签（显示登录/连接状态）

func _ready():
	# 挂载AI聊天节点
	ai_chat_node = preload("res://Scripts/AIChat.gd").new()
	add_child(ai_chat_node)
	ai_chat_node.ai_responded.connect(_on_ai_responded)
	ai_chat_node.ai_error.connect(_on_ai_error)

	# 初始状态隐藏聊天面板，显示登录面板
	chat_panel.visible = false
	login_panel.visible = true
	
	# 客户端一打开就连接 Godot 服务器
	var err = peer.create_client(IP_ADDRESS, PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer # 将当前的网络节点设置为刚才创建的客户端节点
	else:
		status_label.text = "错误: 无法启动 ENet 客户端" # 无法启动客户端时报错
		
	# 连接网络信号以响应连接成功和断开事件
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_error)
	multiplayer.server_disconnected.connect(_on_connection_error)
	
	# 绑定回车键发送消息
	message_input.text_submitted.connect(_on_message_input_text_submitted)
	# 回车提交后继续保持编辑状态（关键：避免看似有焦点却不能继续输入）
	message_input.keep_editing_on_text_submit = true
	# 防止点击发送按钮后按钮抢走键盘焦点
	send_btn.focus_mode = Control.FOCUS_NONE

# 连接服务器成功时的回调
func _on_connected():
	status_label.text = "已连接到服务器，请登录。"

# 连接服务器失败或断开连接时的回调
func _on_connection_error():
	status_label.text = "与服务器断开连接！"

# 点击注册按钮时的回调
func _on_register_pressed():
	# 检查是否已连接到服务器
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		status_label.text = "错误: 未连接到服务器！"
		return
	
	var u_name = usr_input.text.strip_edges()
	var pwd = pwd_input.text
	var email = email_input.text.strip_edges()
	
	if u_name.length() < 5:
		status_label.text = "注册失败: 用户名必须大于等于5个字"
		return
		
	if pwd.length() < 6:
		status_label.text = "注册失败: 密码必须大于等于6位数"
		return
		
	var email_regex = RegEx.new()
	email_regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	if not email_regex.search(email):
		status_label.text = "注册失败: 邮箱格式不正确"
		return
		
	status_label.text = "注册中..." # 显示注册中
	# 发送注册请求到服务器（ID 为 1 代表服务器）
	rpc_id(1, "register_user", u_name, pwd, email)

# 点击登录按钮时的回调
func _on_login_pressed():
	# 检查是否已连接到服务器
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		status_label.text = "错误: 未连接到服务器！"
		return
		
	status_label.text = "登录中..."  # 显示登录中
	# 发送登录请求到服务器
	rpc_id(1, "login_user", usr_input.text.strip_edges(), pwd_input.text)
	username = usr_input.text.strip_edges() # 保存当前尝试登录的用户名

# 接收服务器发回的认证响应
@rpc("any_peer", "call_remote")
func auth_response(success: bool, msg: String):
	print(msg)
	if success:
		if msg == "注册成功":
			status_label.text = "注册成功，请登录"
			return
			
		# 登录成功，隐藏登录面板，显示聊天面板
		login_panel.visible = false
		chat_panel.visible = true
		
		# 登录成功后，清除旧数据
		contact_list.clear()
		contact_list.add_item("公共大厅")
		contact_list.add_item("AI助手") # 新增AI聊天
		contact_list.select(0) # 默认选中第一项（公共大厅）
		chat_histories = {"": "", "AI助手": ""}
		unread_channels.clear()
		contact_update_times.clear()
		current_receiver = ""
		current_mode = ChatMode.PUBLIC
		_update_chat_ui()
		
		# 启动一个定时器，在稍微延迟后把所有频道标记为已读（模拟全都点一遍）
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(_mark_all_as_read)
	else:
		# 登录失败，显示错误信息
		if msg == "用户名或邮箱已存在" or msg.contains("注册"):
			status_label.text = "注册失败: " + msg
		elif msg == "用户名或密码错误" or msg.contains("登录"):
			status_label.text = "登录失败: " + msg
		else:
			status_label.text = "操作失败: " + msg

# 点击发送消息按钮时的回调
func _on_send_pressed():
	var type = "text" # 消息类型为普通文本
	var content = message_input.text # 获取输入的消息内容
	var target = current_receiver # 当前选中的对象
	
	# 消息为空则不发送
	if content.strip_edges() == "":
		return
		
	# 处理与AI的聊天
	if target == "AI助手":
		var err = ai_chat_node.send_prompt(content)
		if err == OK:
			_append_chat_history(target, "[You]: " + content)
			rpc_id(1, "save_ai_message", true, content) # 上传发给AI的消息记录
		message_input.clear()
		message_input.caret_column = 0
		message_input.call_deferred("grab_focus")
		return
	
	# 如果目标为空，则发送公开消息，否则发送私聊消息
	if target == "":
		current_mode = ChatMode.PUBLIC
		rpc_id(1, "send_message", content, type, "") # 向服务器发送广播消息
	else:
		current_mode = ChatMode.PRIVATE
		rpc_id(1, "send_message", content, type, target) # 向服务器发送私聊消息请求
	
	# 在本地聊天记录中追加自己发送的消息
	_append_chat_history(target, "[You]: " + content)
	message_input.clear() # 清空输入框并重置内部编辑状态
	message_input.caret_column = 0
	# 延迟到当前 UI 事件结束后恢复可输入焦点
	message_input.call_deferred("grab_focus")

# 输入框按下回车时的回调
func _on_message_input_text_submitted(_new_text: String):
	# 延迟调用，避免与 LineEdit 的提交事件同帧冲突
	call_deferred("_on_send_pressed")

# 接收别人发来的消息
@rpc("any_peer", "call_remote")
func receive_message(sender: String, receiver: String, content: String, type: String, is_private: bool):
	# 如果是公聊，把它放在公共大厅；
	# 如果是私聊，需判断这个消息是我发给别人的，还是别人发给我的，以此来决定将它放在哪个联系人的历史里
	var target_channel = ""
	if is_private:
		# 如果发送者是我自己，说明这是从历史记录拉取出来的我发给别人的消息
		if sender == username:
			target_channel = receiver # 发给别人，放在别人的聊天窗口
		else:
			target_channel = sender # 别人发给我，放在别人的聊天窗口
			
	# 统一前缀格式为 [名字]: ，不再区分公屏还是私聊
	var prefix = "[" + sender + "]: "
	
	# 如果是我发出的话（比如加载历史记录时），统一显示 [You]: 
	if sender == username:
		prefix = "[You]: "
	
	var final_msg = prefix + content
	if type == "system":
		final_msg = "[color=gray]" + content + "[/color]"

	# 将消息追加到对应聊天记录
	_append_chat_history(target_channel, final_msg)

# 封装好的添加聊天记录函数
func _append_chat_history(channel: String, text: String):
	# 判断该联系人是否已在我方列表内
	if not chat_histories.has(channel):
		chat_histories[channel] = ""
		if channel != "":
			contact_list.add_item(channel)
	
	# 更新最新活动时间
	contact_update_times[channel] = Time.get_unix_time_from_system()
	
	# 拼接文本
	if chat_histories[channel] != "":
		chat_histories[channel] += "\n"
	chat_histories[channel] += text
	
	# 若正好是当前停留的窗口，顺便刷新 UI 文本框
	if current_receiver == channel:
		chat_history.text = chat_histories[channel]
	else:
		# 标记为未读
		unread_channels[channel] = true
		
	# 收到消息后重新排序联系人列表
	_sort_contact_list()

# 对联系人列表排序（按最后消息时间倒序，新获取消息的排在前面）
func _sort_contact_list():
	var items = []
	for i in range(contact_list.item_count):
		var c_name = contact_list.get_item_text(i)
		var r_name = "" if c_name == "公共大厅" else c_name
		var t = contact_update_times.get(r_name, 0.0)
		items.append({"name": c_name, "real_name": r_name, "time": t})
	
	# 按时间倒序排序
	items.sort_custom(func(a, b): return a["time"] > b["time"])
	
	contact_list.clear()
	for item in items:
		contact_list.add_item(item["name"])
		if unread_channels.has(item["real_name"]) and unread_channels[item["real_name"]]:
			# 如果是未读消息，可以初始化其颜色
			pass
	
	# 重新选中当前正在聊天的频道
	for i in range(contact_list.item_count):
		var r_name = "" if contact_list.get_item_text(i) == "公共大厅" else contact_list.get_item_text(i)
		if r_name == current_receiver:
			contact_list.select(i)
			break

func _process(_delta):
	# 实现未读消息频道的文本闪烁效果
	if contact_list == null or contact_list.item_count == 0:
		return
		
	var time_val = sin(Time.get_ticks_msec() / 150.0) # -1 到 1 之间
	var blink_color = Color(1, 0.5, 0) # 橙色作为提示色
	if time_val > 0:
		blink_color = Color(1, 0.8, 0.2) # 闪烁变化
		
	for i in range(contact_list.item_count):
		var c_name = contact_list.get_item_text(i)
		var r_name = "" if c_name == "公共大厅" else c_name
		
		# 如果该频道在未读且不是当前选中频道
		if unread_channels.has(r_name) and unread_channels[r_name] and r_name != current_receiver:
			contact_list.set_item_custom_fg_color(i, blink_color)
		else:
			contact_list.set_item_custom_fg_color(i, Color(1, 1, 1)) # 默认变回白色
			if r_name == current_receiver:
				unread_channels[r_name] = false

# 联系人被选中时的回调
func _on_contact_selected(index: int):
	var selected_text = contact_list.get_item_text(index)
	if selected_text == "公共大厅":
		current_receiver = ""
		current_mode = ChatMode.PUBLIC
	else:
		current_receiver = selected_text
		current_mode = ChatMode.PRIVATE
		
	# 清除该频道的未读标记
	unread_channels[current_receiver] = false
	
	# 刷新聊天区显示的内容
	_update_chat_ui()

# 标记所有频道为已读（模拟把所有窗口点了一遍）
func _mark_all_as_read():
	for channel in chat_histories.keys():
		unread_channels[channel] = false

# 更新聊天区域显示
func _update_chat_ui():
	if current_receiver == "":
		current_chat_label.text = "公共大厅" + (" (在线人数: " + str(online_count) + ")" if online_count > 0 else "")
	else:
		current_chat_label.text = "与 " + current_receiver + " 私聊中"

	# 如果没有该联系人的聊天记录，初始化为空
	if not chat_histories.has(current_receiver):
		chat_histories[current_receiver] = ""
		
	chat_history.text = chat_histories[current_receiver] # 将记录文本显示在UI上

# 点击添加联系人按钮
func _on_add_contact_pressed():
	var new_contact = new_contact_input.text.strip_edges() # 去除前后多余空格
	
	# 防止空内容或添加自己为联系人
	if new_contact == "" or new_contact == username:
		return
	
	# 如果列表里还没有这个人，将其加入联系人列表
	if not chat_histories.has(new_contact):
		chat_histories[new_contact] = ""
		contact_update_times[new_contact] = Time.get_unix_time_from_system()
		contact_list.add_item(new_contact)
		_sort_contact_list()
		new_contact_input.text = "" # 添加后清空输入框

# 接收来自服务器的消息状态更新（例如：delivered）
@rpc("any_peer", "call_remote")
func update_status(status: String):
	pass

# --- RPC STUBS FOR SERVER ---
# 这些是服务器端接收函数的存根（Stub），为了让客户端通过 rpc_id 能够查找到相应的方法名
@rpc("any_peer", "call_remote") func register_user(_u, _p, _e): pass # 注册方法
@rpc("any_peer", "call_remote") func login_user(_u, _p): pass # 登录方法
@rpc("any_peer", "call_remote") func send_message(_c, _t, _tg): pass # 发送消息方法
@rpc("any_peer", "call_remote") func save_ai_message(_is_user: bool, _c: String): pass # 保存AI相关消息

@rpc("authority", "call_remote")
func update_online_count(count: int):
	online_count = count
	_update_chat_ui()

# --- AI 回调 ---
func _on_ai_responded(response_text: String):
	var regex = RegEx.new()
	regex.compile("(?s)<think>.*?</think>")
	var clean_text = regex.sub(response_text, "")
	clean_text = clean_text.strip_edges()
	_append_chat_history("AI助手", "[AI助手]: " + clean_text)
	rpc_id(1, "save_ai_message", false, clean_text) # 上传AI回复的记录

func _on_ai_error(error_msg: String):
	_append_chat_history("AI助手", "[系统警告]: " + error_msg)
