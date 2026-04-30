@tool
extends ProgrammaticTheme

var default_font = "res://themes/fonts/Mozilla_Text/static/MozillaText-Regular.ttf"
var default_font_size = 32

var text_font_color
var background_color
var accent
var default_border_width = 2

var primary = Color(0.0, 0.633, 1.0, 1.0)
const VERBOSITY = Verbosity.QUIET  # or another value.

func setup_light_theme():
	set_save_path("res://themes/generated/light_theme.tres")

	background_color = Color.WHITE
	text_font_color = Color.BLACK
	
	accent = primary

func setup_dark_theme():
	set_save_path("res://themes/generated/dark_theme.tres")

	background_color = Color.BLACK
	text_font_color = Color.WHITE
	
	accent = primary.lightened(0.2)

func define_theme():
	var button_color = background_color
	var button_hover_color = button_color.darkened(0.05)
	var button_pressed_color = button_color.darkened(0.1)
	var button_border_color = Color("#aaa")

	
	
	define_default_font(ResourceLoader.load(default_font))
	define_default_font_size(default_font_size)
	
	define_style("Label", {
		font_color = text_font_color
	})
	
	define_style("PanelContainer", {
		panel = stylebox_flat({
			bg_color = background_color
		})
	})
	
	define_style("Panel", {
		panel = stylebox_flat({
			bg_color = background_color
		})
	})
	
	var button_style = stylebox_flat({
		bg_color = background_color,
		border_color = button_border_color,
		
		border_ = border_width(default_border_width),
		font_color = text_font_color
	})

	var button_hover_style = inherit(button_style, {
		bg_color = button_hover_color
	})

	var button_pressed_style = inherit(button_style, {
		bg_color = button_pressed_color
	})
	
	var button_disabled_style = stylebox_flat({
		bg_color = alpha(background_color, 0.8),
		border_color = alpha(button_border_color, 0.2),
		
		border_ = border_width(default_border_width),
		font_color = alpha(text_font_color, 0.8)
		
	})
	

	define_style("Button", {
		normal = button_style,
		hover = button_hover_style,
		pressed = button_pressed_style,
		disabled = button_disabled_style,
		font_color = text_font_color,
		font_pressed_color = accent,
		font_hover_color = accent,
		font_disabled_color = alpha(text_font_color, 0.4)
	})
	
	var line_edit_style = stylebox_flat({
		bg_color = background_color,
		border_color = button_border_color,
		
		border_ = border_width(default_border_width),
		font_color = text_font_color
	})
	
	define_style("LineEdit", {
		focus = line_edit_style,
		normal = line_edit_style,
		font_color = text_font_color,
		font_placeholder_color = alpha(text_font_color, 0.5),
		caret_color = text_font_color
	})
	
	define_style("MarginContainer", {
		margin_ = margins(20)
	})

func alpha(color: Color, a: float) -> Color:
	return Color(color.r, color.g, color.b, a)
