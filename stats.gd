extends Node2D

@export var label_total_q: Label
@export var label_correct_q: Label
@export var label_acc: Label
@export var label_total_t: Label
@export var label_avg_t: Label
@export var label_score: Label

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)
	
	if Supabase.auth.client == null:
		return
	
	get_stats()

func get_stats() -> void:
	var q = SupabaseQuery.new().select(["was_correct", "time_taken"]).from("quiz_answers")
	var task: DatabaseTask = Supabase.database.query(q)
	await task.completed
	
	# task.data returns an Array of values, of which these values always seem
	# to be of type Dictionary, but the value type of task.data is just Array, 
	# and Godot throws an error if we try to directly assign the task.data to a
	# variable of type Array[Dictionary]. Therefore, check every item to make
	# sure it is a dictionary it safely and print if the task ever returns an 
	# Array of things that are not Dictionaries.
	var data: Array[Dictionary]
	for item in task.data:
		if item is Dictionary:
			data.append(item)
		else:
			assert(false, "Select task returned Array of values that are not Dictionaries!")
	
	var total_q: int = len(data)
	var correct_q: int = 0
	var total_t: float = 0.0
	for dict in data:
		if dict["was_correct"]:
			correct_q += 1
		total_t += dict["time_taken"]
	
	var acc_q: float = 0.0
	var avg_t: float = 0.0
	# avoid div by 0
	if total_q != 0:
		acc_q = 100.0 * float(correct_q) / total_q
		avg_t = total_t / total_q
	
	print(acc_q)
	print(avg_t)
	
	var score = acc_q - (1 * log(avg_t))
	score = score * v(total_q, 10) # reduce score of low total questions answered
	
	print(score)
	
	label_total_q.text = String.num(total_q, 0)
	label_correct_q.text = String.num(correct_q, 0)
	label_acc.text = String.num(acc_q, 2) + "%"
	label_avg_t.text = String.num(avg_t, 2) + "s"
	label_total_t.text = String.num(total_t, 2) + "s"
	if is_nan(score):
		label_score.text = "0.0"
	else:
		label_score.text = String.num(score, 2)
	
	#print(q_correct)
	
	# total questions answered
	# total questions right
	# total time spent on quiz
	# acurracy rate
	# average time taken per question
	# score = avg_acc - (0.001 * log(avg_time))

func v(num: float, k: int):
	return min(num / (num + k), 1.0)
