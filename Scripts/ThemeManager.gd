extends Node

var theme_applied = {}
var timer: Timer

func _ready():
    # 立即应用主题，避免闪烁
    _apply_theme()
    
    # 监听后续动态添加的节点
    get_tree().node_added.connect(_on_node_added)
    
    timer = Timer.new()
    timer.wait_time = 0.5
    timer.autostart = true
    timer.connect("timeout", Callable(self, "_apply_theme"))
    add_child(timer)

func _on_node_added(node: Node):
    if node is Control and not theme_applied.has(node.get_instance_id()):
        _apply_to_control(node)
        theme_applied[node.get_instance_id()] = true

func _apply_theme():
    var root = get_tree().root
    _traverse_and_apply(root)
    
func _traverse_and_apply(node: Node):
    if node is Control:
        if not theme_applied.has(node.get_instance_id()):
            _apply_to_control(node)
            theme_applied[node.get_instance_id()] = true
    for child in node.get_children():
        _traverse_and_apply(child)
        
func _apply_to_control(control: Control):
    # High-tech StyleBox configurations
    if control is Button:
        var sb = StyleBoxFlat.new()
        sb.bg_color = Color(0.0, 0.2, 0.3, 0.7)
        sb.border_width_left = 2
        sb.border_width_right = 2
        sb.border_width_top = 2
        sb.border_width_bottom = 2
        sb.border_color = Color(0.0, 1.0, 1.0, 0.8) # Cyan border
        sb.corner_radius_top_left = 4
        sb.corner_radius_top_right = 4
        sb.corner_radius_bottom_right = 4
        sb.corner_radius_bottom_left = 4
        sb.shadow_color = Color(0, 1, 1, 0.3)
        sb.shadow_size = 5
        control.add_theme_stylebox_override("normal", sb)
        
        var sb_hover = sb.duplicate()
        sb_hover.bg_color = Color(0.0, 0.4, 0.6, 0.9)
        sb_hover.shadow_size = 10
        control.add_theme_stylebox_override("hover", sb_hover)
        
        var sb_pressed = sb.duplicate()
        sb_pressed.bg_color = Color(0.0, 0.1, 0.2, 0.9)
        sb_pressed.border_color = Color(0.0, 0.8, 0.8, 1.0)
        control.add_theme_stylebox_override("pressed", sb_pressed)
        
        var sb_disabled = sb.duplicate()
        sb_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.5)
        sb_disabled.border_color = Color(0.3, 0.5, 0.5, 0.5)
        control.add_theme_stylebox_override("disabled", sb_disabled)
        
        control.add_theme_color_override("font_color", Color(0.8, 1.0, 1.0))
        control.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
        
    elif control is Panel or control is PanelContainer:
        var sb = StyleBoxFlat.new()
        sb.bg_color = Color(0.02, 0.05, 0.1, 0.85) # Deep blue/black
        sb.border_width_left = 1
        sb.border_width_right = 1
        sb.border_width_top = 1
        sb.border_width_bottom = 1
        sb.border_color = Color(0.0, 0.6, 1.0, 0.6)
        sb.corner_radius_top_left = 8
        sb.corner_radius_top_right = 8
        sb.corner_radius_bottom_right = 8
        sb.corner_radius_bottom_left = 8
        control.add_theme_stylebox_override("panel", sb)
    
    elif control is LineEdit or control is TextEdit:
        var sb = StyleBoxFlat.new()
        sb.bg_color = Color(0.0, 0.1, 0.15, 0.7)
        sb.border_width_left = 1
        sb.border_width_right = 1
        sb.border_width_top = 1
        sb.border_width_bottom = 1
        sb.border_color = Color(0.0, 0.8, 1.0, 0.5)
        sb.corner_radius_top_left = 3
        sb.corner_radius_top_right = 3
        sb.corner_radius_bottom_right = 3
        sb.corner_radius_bottom_left = 3
        control.add_theme_stylebox_override("normal", sb)
        
        var sb_focus = sb.duplicate()
        sb_focus.border_color = Color(0.0, 1.0, 1.0, 1.0)
        sb_focus.shadow_color = Color(0.0, 1.0, 1.0, 0.4)
        sb_focus.shadow_size = 4
        control.add_theme_stylebox_override("focus", sb_focus)
        
        var sb_read_only = sb.duplicate()
        sb_read_only.bg_color = Color(0.02, 0.05, 0.1, 0.5)
        control.add_theme_stylebox_override("read_only", sb_read_only)
        
        control.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
        control.add_theme_color_override("font_placeholder_color", Color(0.3, 0.5, 0.6))
        
        if control is TextEdit:
            control.add_theme_color_override("font_readonly_color", Color(1.0, 1.0, 1.0))
        
    elif control is Label:
        control.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
        control.add_theme_color_override("font_shadow_color", Color(0.0, 0.5, 1.0, 0.5))
        control.add_theme_constant_override("shadow_offset_x", 1)
        control.add_theme_constant_override("shadow_offset_y", 1)
        
    elif control is ItemList:
        var sb = StyleBoxFlat.new()
        sb.bg_color = Color(0.0, 0.1, 0.15, 0.7)
        sb.border_width_left = 1
        sb.border_width_right = 1
        sb.border_width_top = 1
        sb.border_width_bottom = 1
        sb.border_color = Color(0.0, 0.7, 0.9, 0.5)
        control.add_theme_stylebox_override("panel", sb)
        control.add_theme_color_override("font_color", Color(0.8, 1.0, 1.0))
        control.add_theme_color_override("font_selected_color", Color(1.0, 1.0, 1.0))
        var sb_selected = StyleBoxFlat.new()
        sb_selected.bg_color = Color(0.0, 0.4, 0.6, 0.8)
        control.add_theme_stylebox_override("selected", sb_selected)
        control.add_theme_stylebox_override("selected_focus", sb_selected)

    # Add dark matrix-like background for root App Nodes
    if control.name in ["App", "Main", "Server"]:
        var has_bg = false
        for child in control.get_children():
            if child.name == "HighTechBG":
                has_bg = true
                break
        
        if not has_bg:
            var bg = ColorRect.new()
            bg.name = "HighTechBG"
            bg.color = Color(0.01, 0.02, 0.05, 1.0) # Very dark blue
            bg.set_anchors_preset(Control.PRESET_FULL_RECT)
            bg.z_index = -100
            
            control.add_child(bg)
            control.move_child(bg, 0)
