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

@export var level_label: Label

var buttons: Array[Button] = []

var saved_correct = ""
var saved_choices: Array[String] = []
var question_time_taken: float = 0.0
var questions_answered: int = 0
var saved_question_id: int = 0

var max_questions: int = -1
var time_left: float = -1.0

var question_history: Array[QuestionData] = []

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

	if CustomQuizSettings.use_settings:
		max_questions = CustomQuizSettings.question_count
		time_left = float(CustomQuizSettings.time_minutes * 60)

	_update_question_tracker()
	_gen_question()

func _gen_question() -> void:
	var task: BaseTask
	if CustomQuizSettings.use_settings and CustomQuizSettings.question_level != -1:
		task = Supabase.database.Rpc("get_question", {"p_level": CustomQuizSettings.question_level})
	else:
		task = Supabase.database.Rpc("get_question")
	await task.completed

	var data = task.data[0]

	saved_question_id = data["id"]
	level_label.text = "Lv %d" % int(data["Level"])

	question_label.text = data["Question"]

	saved_correct = data["Answer"]

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

func _process(delta: float) -> void:

	# Only count down time if a question is active
	if next_button.disabled:
		question_time_taken += delta
		time_left -= delta

	# If using custom quiz settings, check if time has run out
	if time_left <= 0.0 and CustomQuizSettings.use_settings:
		time_left = 0.0
		_change_scene()
		return

	# Update the time label based on whether we're using custom quiz settings or not
	if CustomQuizSettings.use_settings:
		var minutes = int(time_left / 60)
		var seconds = int(time_left) % 60
		time_label.text = "Time Remaining: %02d:%02d" % [minutes, seconds]
	else:
		var minutes = int(question_time_taken / 60)
		var seconds = int(question_time_taken) % 60
		time_label.text = "Question Time: %02d:%02d" % [minutes, seconds]

func _change_scene() -> void:
	if questions_answered == 0:
		get_tree().change_scene_to_file("res://mainMenu.tscn")
		return

	Global.question_history = question_history
	CustomQuizSettings.use_settings = false
	get_tree().change_scene_to_file("res://stats.tscn")
	return


func choice_made(chosen_button: Button) -> void:

	var q: QuestionData = QuestionData.new(
		question_label.text,
		saved_choices,
		saved_correct,
		chosen_button.text,
		question_time_taken
	)

	for button in buttons:
		button.disabled = true

	if q.was_correct:
		result_label.text = "Correct\n"
		Overlay.show_popup("Correct!\n+10")
	else:
		result_label.text = "Incorrect\n"
		Overlay.show_popup("Incorrect\n-5")

	result_label.text += "The correct answer was %s" % q.correct_answer

	questions_answered += 1
	_update_question_tracker()

	insert_answer(q)
	question_history.append(q)

	next_button.disabled = false

func _update_question_tracker() -> void:
	if CustomQuizSettings.use_settings:

		question_tracker_label.text = "Questions Remaining: %d" % (max_questions - questions_answered)

		if questions_answered == max_questions:
			_change_scene()

	else:
		question_tracker_label.text = "Questions Answered: %d" % questions_answered



func insert_answer(question: QuestionData) -> void:
	var query = (
		SupabaseQuery.new()
		.from("quiz_answers")
		.insert(
			[{
				"question_prompt": question.question_prompt,
				"chosen_answer": question.chosen_answer,
				"was_correct": question.was_correct,
				"question_choices": question.question_choices,
				"correct_answer": question.correct_answer,
				"time_taken": question.time_taken,
				"question_id": saved_question_id
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
