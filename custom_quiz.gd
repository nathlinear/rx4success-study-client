extends Node2D

@export var quit_button: Button
@export var next_button: Button

@export var question_label: Label
@export var result_label: Label

@export var button1: Button
@export var button2: Button
@export var button3: Button
@export var button4: Button

@export var question_tracker_label: Label
@export var time_label: Label

var buttons: Array[Button] = []

var correct := ""
var saved_choices: Array[String] = []

var total_questions_answered: int = 0
var max_questions: int = 10

var time_left: float = 300.0
var question_time_taken: float = 0.0
var quiz_over: bool = false

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)

	quit_button.text = "Quit"
	quit_button.pressed.connect(_quit_to_menu)
	next_button.pressed.connect(_gen_question)

	buttons = [button1, button2, button3, button4]

	for button in buttons:
		button.pressed.connect(choice_made.bind(button))
		button.disabled = true

	if not Supabase.database.error.is_connected(_error):
		Supabase.database.error.connect(_error)

	max_questions = CustomQuizSettings.question_count
	time_left = float(CustomQuizSettings.time_minutes * 60)
	total_questions_answered = 0

	_update_time_label()
	_update_question_tracker()
	next_button.disabled = true
	_gen_question()

func _process(delta: float) -> void:
	if quiz_over:
		return

	time_left -= delta
	question_time_taken += delta

	if time_left <= 0.0:
		time_left = 0.0
		_update_time_label()
		_finish_quiz()
		return

	_update_time_label()

func _update_time_label() -> void:
	var minutes = int(time_left / 60)
	var seconds = int(time_left) % 60
	time_label.text = "Time Left: %02d:%02d" % [minutes, seconds]

func _update_question_tracker() -> void:
	question_tracker_label.text = "Question %d / %d" % [total_questions_answered, max_questions]

func _quit_to_menu() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")

func _gen_question() -> void:
	if quiz_over:
		return

	result_label.text = ""
	next_button.disabled = true

	for button in buttons:
		button.disabled = true

	var task = Supabase.database.Rpc("get_question")
	await task.completed

	var data = task.data[0]
	question_label.text = "Level %d - %s" % [int(data["Level"]), data["Question"]]

	correct = data["Answer"]

	var choices: Array[String] = []
	for choice in data["Choices"].split(";"):
		choices.append(choice.strip_edges())

	for i in range(len(buttons)):
		buttons[i].text = choices[i]

	for button in buttons:
		button.disabled = false

	next_button.disabled = true
	result_label.text = ""
	question_time_taken = 0.0
	saved_choices = choices.duplicate()

func choice_made(chosen: Button) -> void:
	if quiz_over:
		return

	if chosen.text == correct:
		result_label.text = "Correct\n"
	else:
		result_label.text = "Incorrect\n"

	result_label.text += "The correct answer was %s" % correct

	for button in buttons:
		button.disabled = true

	total_questions_answered += 1
	_update_question_tracker()

	insert_answer(chosen.text, correct, saved_choices, question_time_taken)

	if total_questions_answered >= max_questions:
		_finish_quiz()
	else:
		next_button.disabled = false

func _finish_quiz() -> void:
	if quiz_over:
		return

	quiz_over = true

	for button in buttons:
		button.disabled = true

	next_button.disabled = true
	result_label.text += "\n\nCustom quiz finished."
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://stats.tscn")

func insert_answer(chosen: String, correct_answer: String, choices: Array[String], time_taken: float) -> void:
	var query = (
		SupabaseQuery.new()
		.from("quiz_answers")
		.insert(
			[{
				"chosen_answer": chosen,
				"was_correct": chosen == correct_answer,
				"question_choices": choices,
				"correct_answer": correct_answer,
				"time_taken": time_taken
			}]
		)
	)

	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed
	print(task.data)
	print(task.error)

func _error(err) -> void:
	result_label.text = str(err)

func _exit_tree() -> void:
	if Supabase.database.error.is_connected(_error):
		Supabase.database.error.disconnect(_error)
