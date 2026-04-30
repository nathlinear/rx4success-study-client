extends Node2D

@export var grid: GridContainer
@export var statOptions: OptionButton
@export var timeOptions: OptionButton

func _ready() -> void:
	
	statOptions.item_selected.connect(_on_stat_options_item_selected)
	timeOptions.item_selected.connect(_on_time_options_item_selected)

	update_leaderboard()

func create_listing(username: String, score: float):
	if score == 0:
		return
	var leftLabel = Label.new()
	leftLabel.text = username
	var rightLabel = Label.new()
	rightLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rightLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rightLabel.text = String.num(score, 2).pad_decimals(2) + "   "

	leftLabel.custom_minimum_size = Vector2(0, 30)
	rightLabel.custom_minimum_size = Vector2(0, 30)

	grid.add_child(leftLabel)
	grid.add_child(rightLabel)

func _on_stat_options_item_selected(_index: int) -> void:
	update_leaderboard()

func _on_time_options_item_selected(_index: int) -> void:
	update_leaderboard()

func _reset_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	
func update_leaderboard() -> void:
	_reset_grid()

	var past_days: int = -1

	match timeOptions.selected:
		0:
			past_days = -1 # all time
		1:
			past_days = 30
		2:
			past_days = 7

	var task: BaseTask
	if past_days > 0:
		task = Supabase.database.Rpc("get_leaderboard", {"p_days": past_days})
	else:
		task = Supabase.database.Rpc("get_leaderboard")
	await task.completed
	print(task.data)

	# username: statistic
	var user_stat_array: Array[Dictionary] = []

	for data_dict in task.data:
		match statOptions.selected:
			0:
				# Total correct
				user_stat_array.append({"username": data_dict["username"], "statistic": data_dict["total_correct"]})

			1:
				# Total answered
				var total_answered = float(data_dict["total_questions_answered"])
				user_stat_array.append({"username": data_dict["username"], "statistic": total_answered})
			2:
				# Accuracy
				var accuracy: float
				var total_answered = float(data_dict["total_questions_answered"])

				if total_answered > 0:
					accuracy = data_dict["total_correct"] / total_answered
				else:
					accuracy = 0.0

				user_stat_array.append({"username": data_dict["username"], "statistic": accuracy * 100.0})
			3:
				# Average time
				var average_time: float
				var total_answered = float(data_dict["total_questions_answered"])
				if total_answered > 0:
					average_time = data_dict["total_time"] / total_answered
				else:
					average_time = 0.0
				user_stat_array.append({"username": data_dict["username"], "statistic": average_time})
			4:
				# Total time
				user_stat_array.append({"username": data_dict["username"], "statistic": data_dict["total_time"]})
			5:
				# Score
				var score = data_dict["score"]
				user_stat_array.append({"username": data_dict["username"], "statistic": score})
	
	build_listings(user_stat_array)

func build_listings(user_stat_array: Array) -> void:
	# Defensive copy
	var arr: Array = user_stat_array.duplicate(true)

	# Build array of pairs [stat_value, entry_dict] without one-liners
	var pairs: Array = []
	for i in range(arr.size()):
		var entry = arr[i]
		var stat_val: float = 0.0

		if typeof(entry) == TYPE_DICTIONARY:
			if entry.has("statistic"):
				stat_val = float(entry["statistic"])

		var pair: Array = []
		pair.append(stat_val)
		pair.append(entry)
		pairs.append(pair)

	# Sort ascending by numeric key (built-in sort compares first element of each pair)
	pairs.sort()

	# Debug prints

	var take_lowest: bool = false
	if statOptions.selected == 3:
		take_lowest = true

	# Pop entries in the desired order and create listings (no one-liners)
	if take_lowest:
		while pairs.size() > 0:
			var pair_front: Array = pairs.pop_front()
			var entry_dict: Dictionary = pair_front[1]

			var username: String = "?"
			var stat_num: float = 0.0

			if typeof(entry_dict) == TYPE_DICTIONARY:
				if entry_dict.has("username"):
					username = String(entry_dict["username"])
				if entry_dict.has("statistic"):
					stat_num = float(entry_dict["statistic"])

			create_listing(username, stat_num)
	else:
		while pairs.size() > 0:
			var pair_back: Array = pairs.pop_back()
			var entry_dict: Dictionary = pair_back[1]

			var username: String = "?"
			var stat_num: float = 0.0

			if typeof(entry_dict) == TYPE_DICTIONARY:
				if entry_dict.has("username"):
					username = String(entry_dict["username"])
				if entry_dict.has("statistic"):
					stat_num = float(entry_dict["statistic"])

			create_listing(username, stat_num)
