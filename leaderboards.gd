extends Node2D

@export var grid: GridContainer

func _ready() -> void:
	ThemeManager.detect_system_theme()
	ThemeManager.apply_theme($CanvasLayer/Control)
	
	var task = Supabase.database.Rpc("get_leaderboard")
	await task.completed
	print(task.data)

	for item in task.data:
		if !(item is Dictionary):
			continue
		
		var total_questions = item["total_questions_answered"]
		var accuracy: float = item["total_correct"] / total_questions
		var average_time: float = item["total_time"] / total_questions
		var score: float = Statistics.calc_score(accuracy * 100.0, average_time, total_questions)
		print(item["username"])
		print(score)
		print("---")
		create_listing(item["username"], score)

func create_listing(username: String, score: float):
	var leftLabel = Label.new()
	leftLabel.text = username
	var rightLabel = Label.new()
	rightLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rightLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rightLabel.text = String.num(score, 2) + "   "
	
	grid.add_child(leftLabel)
	grid.add_child(rightLabel)
