extends Control

# 当点击"启动服务器"按钮时调用
func _on_start_server_pressed():
    # 切换到服务器场景
    get_tree().change_scene_to_file("res://Scenes/Server.tscn")

# 当点击"启动客户端"按钮时调用
func _on_start_client_pressed():
    # 切换到客户端场景
    get_tree().change_scene_to_file("res://Scenes/Client.tscn")
