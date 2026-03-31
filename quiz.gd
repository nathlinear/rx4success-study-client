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

var correct = ""
var saved_choices: Array[String] = []
var time_taken: float = 0.0
var questions_answered: int = 0

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)

	quit_button.pressed.connect(_change_scene)
	next_button.pressed.connect(_gen_question)

	buttons.append(button1)
	buttons.append(button2)
	buttons.append(button3)
	buttons.append(button4)

	for button in buttons:
		button.pressed.connect(choice_made.bind(button))
		button.disabled = true

	if not Supabase.database.error.is_connected(_error):
		Supabase.database.error.connect(_error)

	questions_answered = 0
	_update_question_tracker()
	_gen_question()

func _gen_question() -> void:
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
	time_taken = 0.0
	saved_choices = choices.duplicate()

func _process(delta: float) -> void:
	time_taken += delta

	var minutes = int(time_taken / 60)
	var seconds = int(time_taken) % 60

	time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _change_scene() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")

func choice_made(chosen: Button) -> void:
	if chosen.text == correct:
		result_label.text = "Correct\n"
	else:
		result_label.text = "Incorrect\n"

	result_label.text += "The correct answer was %s" % correct

	for button in buttons:
		button.disabled = true

	questions_answered += 1
	_update_question_tracker()

	insert_answer(chosen.text, correct, saved_choices, time_taken)
	next_button.disabled = false

func _update_question_tracker() -> void:
	question_tracker_label.text = "Answered: %d" % questions_answered

func insert_answer(chosen: String, correct_answer: String, choices: Array[String], time: float) -> void:
	var query = (
		SupabaseQuery.new()
		.from("quiz_answers")
		.insert(
			[{
				"chosen_answer": chosen,
				"was_correct": chosen == correct_answer,
				"question_choices": choices,
				"correct_answer": correct_answer,
				"time_taken": time
			}]
		)
	)
	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed
	print(task.data)
	print(task.error)

func _error(err):
	result_label.text = str(err)

func _exit_tree() -> void:
	if Supabase.database.error.is_connected(_error):
		Supabase.database.error.disconnect(_error)
