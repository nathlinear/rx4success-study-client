extends Node2D

@export var time_input: LineEdit
@export var questions_input: LineEdit
@export var start_button: Button
@export var back_button: Button
@export var level_picker: OptionButton

var question_levels: Array[int] = [2,4,5,6,7,8,9,10,11,12,13]

func _ready() -> void:

	if time_input == null or questions_input == null or start_button == null or back_button == null:
		push_error("One or more exported nodes are not assigned in the Inspector.")
		return

	# Leave fields empty at start
	time_input.text = ""
	questions_input.text = ""

	# Mobile keyboard hint
	time_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	questions_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER

	# Keep only digits
	time_input.text_changed.connect(_on_time_text_changed)
	questions_input.text_changed.connect(_on_questions_text_changed)

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
		time_val = 120
	else:
		time_val = int(time_input.text)

	if questions_input.text.strip_edges() == "":
		question_val = 90
	else:
		question_val = int(questions_input.text)

	# Clamp to allowed range
	time_val = clamp(time_val, 1, 300)
	question_val = clamp(question_val, 1, 500)

	CustomQuizSettings.time_minutes = time_val
	CustomQuizSettings.question_count = question_val

	CustomQuizSettings.use_settings = true
	get_tree().change_scene_to_file("res://scenes/quiz.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
