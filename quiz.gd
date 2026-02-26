extends Node2D


@export var quit_button: Button
@export var next_button: Button

@export var question_label: Label
@export var result_label: Label

@export var button1: Button
@export var button2: Button
@export var button3: Button
@export var button4: Button

var buttons: Array[Button] = []

var correct = ""

func _ready() -> void:
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
	
func _change_scene() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")

func _gen_question() -> void:
	Supabase.database.Rpc("get_question")

func _response(msg: Dictionary):
	# msg is a dictionary with keys name, correct, wrong1, wrong2, and wrong3
	
	var q = "Which of the following is a common indication for %s?" % msg.get("name")
	question_label.text = q
	
	# save correct answer for later checking
	correct = msg.get("correct")
	
	# make an array of all the choices, randomize it, then assign each buttonn
	var choices: Array[String] = []
	choices.append(msg.get("correct"))
	choices.append(msg.get("wrong1"))
	choices.append(msg.get("wrong2"))
	choices.append(msg.get("wrong3"))
	
	choices.shuffle()
	
	for i in range(len(buttons)):
		buttons[i].text = choices[i]
	
	# reenable all buttons
	for button in buttons:
		button.disabled = false
	
	result_label.text = ""

func choice_made(chosen: Button):
	
	if chosen.text == correct:
		result_label.text = "Correct\n"
	else:
		result_label.text = "Incorrect\n"
	
	result_label.text += "The correct answer was %s" % correct
	
	# disable all buttons until next question
	for button in buttons:
		button.disabled = true
