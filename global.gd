extends Node

var num: float = 0.0
var question_history: Array[QuestionData] = []
var use_question_history: bool = false








enum {
	LIGHT,
	DARK
}

var theme_setting = DARK

func _ready() -> void:
	get_tree().scene_changed.connect(_apply_theme)
	_apply_theme()

func _apply_theme() -> void:
	var control = get_tree().current_scene.find_child("Control")
	if control is not Control:
		return
	
	match theme_setting:
		LIGHT:
			control.theme = load("res://themes/generated/light_theme.tres")
		DARK:
			control.theme = load("res://themes/generated/dark_theme.tres")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"1":
				theme_setting = LIGHT
				_apply_theme()
			"2":
				theme_setting = DARK
				_apply_theme()
