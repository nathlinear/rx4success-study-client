extends RefCounted
class_name QuestionData

var question_prompt: String
var question_choices: Array
var correct_answer: String
var chosen_answer: String
var time_taken: float
var was_correct: bool

@warning_ignore("shadowed_variable")
func _init(question_prompt: String, question_choices: Array, correct_answer: String, user_answer: String, time_taken: float) -> void:
	self.question_prompt = question_prompt
	self.question_choices = question_choices
	self.correct_answer = correct_answer
	self.chosen_answer = user_answer
	self.was_correct = user_answer == correct_answer
	self.time_taken = time_taken

func _to_string() -> String:
	return str([question_prompt, question_choices, correct_answer, chosen_answer, was_correct, time_taken])

func to_dictionary() -> Dictionary:
	return {
		"question_prompt": question_prompt,
		"question_choices": question_choices,
		"correct_answer": correct_answer,
		"chosen_answer": chosen_answer,
		"was_correct": was_correct,
		"time_taken": time_taken
	}
