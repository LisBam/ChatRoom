import os
from flask import Flask, request, jsonify
import mysql.connector
from datetime import datetime

# 初始化 Flask 应用
app = Flask(__name__)

# 数据库配置（根据你本地的 MySQL 设置进行调整）
# Database configuration (adjust user and password to your local MySQL settings)
DB_CONFIG = {
    'host': '127.0.0.1', # 数据库主机地址
    'user': 'root',      # 数据库用户名
    'password': 'zlm258078', # 在这里填入你的 MySQL 密码
    'database': 'chat_room', # 数据库名称
    'autocommit': True       # 启用自动提交
}

# 获取数据库连接的辅助函数
def get_db_connection():
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as err:
        print(f"连接 MySQL 数据库失败: {err}")
        return None

# 注册 API 接口
@app.route('/api/register', methods=['POST'])
def register():
    data = request.json # 获取前端传来的 JSON 数据
    username = data.get('username') # 获取用户名
    password = data.get('password') # 获取密码（在真实应用中，这里应该进行哈希加密！） # In a real app, hash this!
    email = data.get('email')       # 获取邮箱

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'msg': '数据库连接错误'}) # 数据库连接失败

    cursor = conn.cursor()
    try:
        # 检查用户名或邮箱是否已存在
        cursor.execute("SELECT id FROM Users WHERE username = %s OR email = %s", (username, email))
        if cursor.fetchone():
            return jsonify({'success': False, 'msg': '用户名或邮箱已存在'}) # 已存在提示错误

        # 将新用户数据插入数据库
        cursor.execute(
            "INSERT INTO Users (username, password_hash, email) VALUES (%s, %s, %s)",
            (username, password, email)
        )
        return jsonify({'success': True, 'msg': '用户注册成功'}) # 注册成功
    except Exception as e:
        return jsonify({'success': False, 'msg': str(e)}) # 发生异常时返回错误信息
    finally:
        cursor.close()
        conn.close()

# 登录 API 接口
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json # 获取 JSON 数据
    username = data.get('username') # 获取用户名
    password = data.get('password') # 获取密码

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'msg': '数据库连接错误'}) # 数据库连接失败

    cursor = conn.cursor(dictionary=True)
    try:
        # 验证用户名和密码
        cursor.execute("SELECT id, username FROM Users WHERE username = %s AND password_hash = %s", (username, password))
        user = cursor.fetchone()
        if user:
            return jsonify({'success': True, 'msg': '登录成功', 'user_id': user['id']}) # 登录成功返回 user_id
        else:
            return jsonify({'success': False, 'msg': '用户名或密码无效'}) # 信息不匹配
    except Exception as e:
        return jsonify({'success': False, 'msg': str(e)}) # 发生异常
    finally:
        cursor.close()
        conn.close()

# 报错消息 API 接口
@app.route('/api/save_message', methods=['POST'])
def save_message():
    data = request.json # 获取 JSON 数据
    sender_name = data.get('sender') # 发送者用户名
    receiver_name = data.get('receiver') # 接收者用户名（如果没有则是公开消息）
    content = data.get('content') # 消息内容
    msg_type = data.get('type', 'text') # 消息类型（默认为 text）

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False}) # 数据库连接失败

    cursor = conn.cursor(dictionary=True)
    try:
        # 查找发送者的 ID
        cursor.execute("SELECT id FROM Users WHERE username = %s", (sender_name,))
        sender = cursor.fetchone()
        sender_id = sender['id'] if sender else None

        receiver_id = None
        # 如果有接收者名字，查找接收者的 ID
        if receiver_name:
            cursor.execute("SELECT id FROM Users WHERE username = %s", (receiver_name,))
            receiver = cursor.fetchone()
            if receiver:
                receiver_id = receiver['id']
        
        # 确保发送者存在
        if not sender_id:
            return jsonify({'success': False, 'msg': '未找到发送者'})

        # 将消息插入数据库
        cursor.execute(
            "INSERT INTO Messages (sender_id, receiver_id, content, msg_type) VALUES (%s, %s, %s, %s)",
            (sender_id, receiver_id, content, msg_type)
        )
        return jsonify({'success': True}) # 保存成功
    except Exception as e:
        return jsonify({'success': False, 'msg': str(e)}) # 发生异常
    finally:
        cursor.close()
        conn.close()

# 获取历史消息记录 API 接口
@app.route('/api/get_history', methods=['POST'])
def get_history():
    data = request.json # 获取 JSON 数据
    username = data.get('username') # 获取请求历史记录的用户名

    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'history': []}) # 数据库连接失败

    cursor = conn.cursor(dictionary=True)
    try:
        # 查找请求用户的 ID
        cursor.execute("SELECT id FROM Users WHERE username = %s", (username,))
        user = cursor.fetchone()
        user_id = user['id'] if user else None

        if not user_id:
            return jsonify({'success': False, 'history': []})

        # 查询与该用户相关的历史消息：
        # 包括：接收者是该用户的私聊消息，接收者为空的公开消息，以及该用户发送的消息，按时间升序排序
        query = """
            SELECT m.content, m.msg_type as type, s.username as sender, r.username as receiver
            FROM Messages m
            JOIN Users s ON m.sender_id = s.id
            LEFT JOIN Users r ON m.receiver_id = r.id
            WHERE m.receiver_id = %s OR m.receiver_id IS NULL OR m.sender_id = %s
            ORDER BY m.created_at ASC
        """
        cursor.execute(query, (user_id, user_id))
        history = cursor.fetchall()
        
        # 为了兼容 Godot 客户端端处理逻辑，将 NULL 的 receiver 替换为空字符串
        # Replace NULL receiver with empty string for Godot compatibility
        for msg in history:
            if not msg['receiver']:
                msg['receiver'] = ""

        return jsonify({'success': True, 'history': history}) # 返回成功标志及历史消息列表
    except Exception as e:
        return jsonify({'success': False, 'history': [], 'msg': str(e)}) # 发生异常
    finally:
        cursor.close()
        conn.close()

# 启动 Flask 服务，监听所有可用 IP 的 5000 端口
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
