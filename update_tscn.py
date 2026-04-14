import re

with open("Scenes/Client.tscn", "r", encoding="utf-8") as f:
    tscn = f.read()

chat_panel_start = tscn.find('[node name="ChatPanel"')
if chat_panel_start == -1:
    print("ChatPanel not found")
    exit(1)

chat_panel_decl_end = tscn.find('[node name="VBoxContainer"', chat_panel_start)
before_chat_panel = tscn[:chat_panel_start]
chat_panel_decl = tscn[chat_panel_start:chat_panel_decl_end]

new_nodes = """
[node name="ChatLayout" type="HBoxContainer" parent="ChatPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2

[node name="Sidebar" type="VBoxContainer" parent="ChatPanel/ChatLayout"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 0.3

[node name="ContactList" type="ItemList" parent="ChatPanel/ChatLayout/Sidebar"]
layout_mode = 2
size_flags_vertical = 3

[node name="AddContactBox" type="HBoxContainer" parent="ChatPanel/ChatLayout/Sidebar"]
layout_mode = 2

[node name="NewContactInput" type="LineEdit" parent="ChatPanel/ChatLayout/Sidebar/AddContactBox"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "添加联系人..."

[node name="AddContactBtn" type="Button" parent="ChatPanel/ChatLayout/Sidebar/AddContactBox"]
layout_mode = 2
text = "+"

[node name="ChatArea" type="VBoxContainer" parent="ChatPanel/ChatLayout"]
layout_mode = 2
size_flags_horizontal = 3

[node name="CurrentChatLabel" type="Label" parent="ChatPanel/ChatLayout/ChatArea"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "公共大厅"
horizontal_alignment = 1

[node name="HistoryText" type="TextEdit" parent="ChatPanel/ChatLayout/ChatArea"]
layout_mode = 2
size_flags_vertical = 3
editable = false
wrap_mode = 1

[node name="InputLayout" type="HBoxContainer" parent="ChatPanel/ChatLayout/ChatArea"]
layout_mode = 2

[node name="MessageInput" type="LineEdit" parent="ChatPanel/ChatLayout/ChatArea/InputLayout"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "输入消息..."

[node name="SendBtn" type="Button" parent="ChatPanel/ChatLayout/ChatArea/InputLayout"]
layout_mode = 2
text = "发送"

"""

new_connections = """[connection signal="pressed" from="LoginPanel/VBox/LoginBtn" to="." method="_on_login_pressed"]
[connection signal="pressed" from="LoginPanel/VBox/RegisterBtn" to="." method="_on_register_pressed"]
[connection signal="pressed" from="ChatPanel/ChatLayout/ChatArea/InputLayout/SendBtn" to="." method="_on_send_pressed"]
[connection signal="item_selected" from="ChatPanel/ChatLayout/Sidebar/ContactList" to="." method="_on_contact_selected"]
[connection signal="pressed" from="ChatPanel/ChatLayout/Sidebar/AddContactBox/AddContactBtn" to="." method="_on_add_contact_pressed"]
"""

final_tscn = before_chat_panel + chat_panel_decl + new_nodes + new_connections

with open("Scenes/Client.tscn", "w", encoding="utf-8") as f:
    f.write(final_tscn)
print("Updated tscn")
