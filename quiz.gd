extends Node2D


@export var quit_button: Button
@export var next_button: Button

@export var question_label: Label
@export var result_label: Label

@export var button1: Button
@export var button2: Button
@export var button3: Button
@export var button4: Button

@export var time_label: Label

var buttons: Array[Button] = []

var correct = ""
var saved_choices: Array[String] = []
var time_taken: float = 0.0

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)
	
	quit_button.pressed.connect(_change_scene)
	next_button.pressed.connect(_gen_question)
	
	buttons.append(button1)
	buttons.append(button2)
	buttons.append(button3)
	buttons.append(button4)
	
	# disable buttons initially so that things dont break
	for button in buttons:
		button.pressed.connect(choice_made.bind(button))
		button.disabled = true
	
	Supabase.database.rpc_completed.connect(_response)
	Supabase.database.error.connect(_error)
	
	_gen_question()

func _process(delta: float) -> void:
	time_taken += delta

	var minutes = int(time_taken) / 60
	var seconds = int(time_taken) % 60

	time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _change_scene() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")

func _gen_question() -> void:
	Supabase.database.Rpc("get_question")

func _response(msg: String):
	# msg is a dictionary with keys name, correct, wrong1, wrong2, and wrong3
	var arr = msg.split("||")
	
	var q = "Which of the following is a common indication for %s?" % arr[0]
	question_label.text = q
	
	# save correct answer for later checking
	correct = arr[1]
	
	# make an array of all the choices, randomize it, then assign each buttonn
	var choices: Array[String] = []
	for i in range(4):
		choices.append(arr[i])
	
	choices.shuffle()
	saved_choices = choices.duplicate()
	
	for i in range(len(buttons)):
		buttons[i].text = choices[i]
	
	# reenable all buttons
	for button in buttons:
		button.disabled = false
	
	result_label.text = ""
	time_taken = 0.0

func choice_made(chosen: Button):
	
	if chosen.text == correct:
		result_label.text = "Correct\n"
	else:
		result_label.text = "Incorrect\n"
	
	result_label.text += "The correct answer was %s" % correct
	
	# disable all buttons until next question
	for button in buttons:
		button.disabled = true
	
	insert_answer(chosen.text, correct, saved_choices, 0.1)


func insert_answer(chosen: String, correct: String, choices: Array[String], time: float) -> void:
	var query = (
		SupabaseQuery.new()
		.from("quiz_answers")
		.insert(
			[{
				"chosen_answer": chosen,
				"was_correct": chosen == correct,
				"question_choices": choices,
				"correct_answer": correct,
				"time_taken": time_taken
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
	if Supabase.database.rpc_completed.is_connected(_response):
		Supabase.database.rpc_completed.disconnect(_response)

	if Supabase.database.error.is_connected(_error):
		Supabase.database.error.disconnect(_error)
