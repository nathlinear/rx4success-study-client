extends Node2D

@export var time_input: LineEdit
@export var questions_input: LineEdit
@export var start_button: Button
@export var back_button: Button

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)

	if time_input == null or questions_input == null or start_button == null or back_button == null:
		push_error("One or more exported nodes are not assigned in the Inspector.")
		return

	# Leave fields empty at start
	time_input.text = ""
	questions_input.text = ""

	# Optional placeholder text
	time_input.placeholder_text = "1 - 20"
	questions_input.placeholder_text = "10 - 50"

	# Mobile keyboard hint
	time_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	questions_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER

	# Keep only digits
	time_input.text_changed.connect(_on_time_text_changed)
	questions_input.text_changed.connect(_on_questions_text_changed)

	start_button.pressed.connect(_start_custom_quiz)
	back_button.pressed.connect(_go_back)

func _on_time_text_changed(new_text: String) -> void:
	var cleaned := _digits_only(new_text)
	if cleaned != new_text:
		time_input.text = cleaned
		time_input.caret_column = time_input.text.length()

func _on_questions_text_changed(new_text: String) -> void:
	var cleaned := _digits_only(new_text)
	if cleaned != new_text:
		questions_input.text = cleaned
		questions_input.caret_column = questions_input.text.length()

func _digits_only(value: String) -> String:
	var result := ""
	for ch in value:
		if ch >= "0" and ch <= "9":
			result += ch
	return result

func _start_custom_quiz() -> void:
	var time_val: int
	var question_val: int

	# If blank, use defaults
	if time_input.text.strip_edges() == "":
		time_val = 5
	else:
		time_val = int(time_input.text)

	if questions_input.text.strip_edges() == "":
		question_val = 10
	else:
		question_val = int(questions_input.text)

	# Clamp to allowed range
	time_val = clamp(time_val, 1, 20)
	question_val = clamp(question_val, 10, 50)

	CustomQuizSettings.time_minutes = time_val
	CustomQuizSettings.question_count = question_val

	get_tree().change_scene_to_file("res://custom_quiz.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")
