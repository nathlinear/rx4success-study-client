extends Node2D

@export var time_spinbox: SpinBox
@export var questions_spinbox: SpinBox
@export var start_button: Button
@export var back_button: Button
@export var level_picker: OptionButton

var question_levels: Array[int] = [2,4,5,6,7,8,9,10,11,12,13]

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

	start_button.pressed.connect(_start_custom_quiz)
	back_button.pressed.connect(_go_back)
	level_picker.item_selected.connect(_level_selected)
	add_question_levels()

func add_question_levels():
	for level in question_levels:
		# Note that index 0 is already used for Any
		level_picker.add_item(str(level))

func _level_selected(index: int):
	if index == 0:
		CustomQuizSettings.question_level = -1
	else:
		var level = question_levels[index-1]
		CustomQuizSettings.question_level = level


func _start_custom_quiz() -> void:
	CustomQuizSettings.time_minutes = int(time_spinbox.value)
	CustomQuizSettings.question_count = int(questions_spinbox.value)
	CustomQuizSettings.use_settings = true
	get_tree().change_scene_to_file("res://quiz.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")
