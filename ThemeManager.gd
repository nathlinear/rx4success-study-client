extends Node

var is_dark_mode: bool = true

var bg_dark := Color("#111111")
var text_dark := Color("#ffffff")
var button_dark := Color("#222222")

var bg_light := Color("#ffffff")
var text_light := Color("#111111")
var button_light := Color("#dddddd")

func detect_system_theme() -> void:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var result = JavaScriptBridge.eval(
			"window.matchMedia('(prefers-color-scheme: dark)').matches"
		)
		is_dark_mode = bool(result)
	else:
		is_dark_mode = true

func apply_theme(root: Control) -> void:
	if root == null:
		return

	var bg = bg_dark if is_dark_mode else bg_light
	var text = text_dark if is_dark_mode else text_light
	var button_bg = button_dark if is_dark_mode else button_light

	var bg_node = root.get_node_or_null("Background")
	if bg_node and bg_node is ColorRect:
		bg_node.color = bg

	_apply_recursive(root, text, button_bg)

func _apply_recursive(node: Node, text_color: Color, button_color: Color) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", text_color)

	elif node is Button:
		node.add_theme_color_override("font_color", text_color)

		var style := StyleBoxFlat.new()
		style.bg_color = button_color
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		node.add_theme_stylebox_override("normal", style)

		var hover := style.duplicate()
		hover.bg_color = button_color.lightened(0.1)
		node.add_theme_stylebox_override("hover", hover)

		var pressed := style.duplicate()
		pressed.bg_color = button_color.darkened(0.1)
		node.add_theme_stylebox_override("pressed", pressed)

	elif node is LineEdit:
		node.add_theme_color_override("font_color", text_color)

	for child in node.get_children():
		_apply_recursive(child, text_color, button_color)
