extends Node2D
class_name Statistics

@export var label_total_q: Label
@export var label_correct_q: Label
@export var label_acc: Label
@export var label_total_t: Label
@export var label_avg_t: Label
@export var xp_num_label: Label
@export var label_history: Label
@export var xp_text_label: Label
@export var quit_button: Button

func _ready() -> void:
	
	if Supabase.auth.client == null:
		return
	
	if Global.question_history != []:

		calc_stats(Global.question_history)
		# Global.question_history = []
	else:
		var questions = await get_supabase_questions()
		calc_stats(questions)
	
	quit_button.pressed.connect(_exit)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.as_text() == "R":
			print("Refreshing stats...")
			calc_stats(Global.question_history)
		if event.as_text() == "S":
			print("Refreshing stats...")
			calc_stats(await get_supabase_questions())

func _exit() -> void:
	Global.question_history = []
	Global.use_question_history = false
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

func get_supabase_questions() -> Array[QuestionData]:
	var q = SupabaseQuery.new().select(["*"]).from("quiz_answers").order("created_at", 1)
	var task: DatabaseTask = Supabase.database.query(q)
	await task.completed
	
	var supaData: Array = task.data
	var questions: Array[QuestionData]

	for dictionary in supaData:

		questions.append(QuestionData.new(
			dictionary["question_prompt"] if dictionary["question_prompt"] != null else "",
			dictionary["question_choices"],
			dictionary["correct_answer"],
			dictionary["chosen_answer"],
			dictionary["time_taken"]
		))
		
	return questions

static func calc_score(accuracy_percent: float, total_time: float, total_q: int) -> float:
	return (accuracy_percent * total_q) / total_time

func calc_stats(questions: Array[QuestionData]) -> void:

	var total_q: int = len(questions)
	var correct_q: int = 0
	var total_t: float = 0.0
	var score: float = 0.0
	label_history.text = ""
	for q: QuestionData in questions:
		total_t += q.time_taken

		var string: String = "Q: " + q.question_prompt + "\n" + "Your answer: " + q.chosen_answer + "\n" + "Correct answer: " + q.correct_answer + "\n" + "Time taken: " + String.num(q.time_taken, 2) + "s\n" + "\n\n"
		label_history.text += string
		if q.was_correct:
			correct_q += 1
	
	var acc_q: float = 0.0
	var avg_t: float = 0.0
	# avoid div by 0
	if total_q != 0:
		acc_q = 100.0 * float(correct_q) / total_q
		avg_t = total_t / total_q
	
	
	score = calc_score(acc_q, total_t, total_q)
	
	
	label_total_q.text = String.num(total_q, 0)
	label_correct_q.text = String.num(correct_q, 0)
	label_acc.text = String.num(acc_q, 2) + "%"
	label_avg_t.text = String.num(avg_t, 2) + "s"
	label_total_t.text = String.num(total_t, 2) + "s"

	if Global.question_history == []:
		var task = Supabase.database.Rpc("calculate_quiz_score")
		await task.completed

		score = task.data
	
	xp_num_label.text = String.num(score, 0)

	# If the user got to stats not from main menu, show "Quiz XP" instead of "Overall XP"
	if CustomQuizSettings.use_settings or Global.question_history != []:
		xp_text_label.text = "Quiz Score"
	else:
		xp_text_label.text = "Total Score"
