extends OptionButton

var question_levels: Array[int] = [2,4,5,6,7,8,9,10,11,12,13]

func _ready() -> void:
	for level in question_levels:
		add_item(str(level))
