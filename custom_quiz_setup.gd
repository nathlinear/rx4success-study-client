extends Node2D

@export var time_spinbox: SpinBox
@export var questions_spinbox: SpinBox
@export var start_button: Button
@export var back_button: Button

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)
	
	time_spinbox.min_value = 1
	time_spinbox.max_value = 20
	time_spinbox.step = 1
	time_spinbox.value = CustomQuizSettings.time_minutes

	questions_spinbox.min_value = 10
	questions_spinbox.max_value = 50
	questions_spinbox.step = 1
	questions_spinbox.value = CustomQuizSettings.question_count

	var time_edit := time_spinbox.get_line_edit()
	var questions_edit := questions_spinbox.get_line_edit()

	time_edit.focus_entered.connect(_on_time_focus)
	questions_edit.focus_entered.connect(_on_questions_focus)

	start_button.pressed.connect(_start_custom_quiz)
	back_button.pressed.connect(_go_back)

func _on_time_focus() -> void:
	time_spinbox.get_line_edit().call_deferred("select_all")

func _on_questions_focus() -> void:
	questions_spinbox.get_line_edit().call_deferred("select_all")

func _start_custom_quiz() -> void:
	var time_val := int(time_spinbox.value)
	var question_val := int(questions_spinbox.value)

	time_val = clamp(time_val, 1, 20)
	question_val = clamp(question_val, 10, 50)

	CustomQuizSettings.time_minutes = time_val
	CustomQuizSettings.question_count = question_val

	get_tree().change_scene_to_file("res://custom_quiz.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")
