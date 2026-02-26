extends Node2D


@export var quiz_button: Button
@export var stats_button: Button

func _ready() -> void:
	print(Supabase.auth.client)
	quiz_button.pressed.connect(_go_to_quiz)
	stats_button.pressed.connect(_get_question)
	
	Supabase.database.rpc_completed.connect(_response)
	Supabase.database.error.connect(_error)

func _go_to_quiz():
	get_tree().change_scene_to_file("res://quiz.tscn")

func _get_question():
	Supabase.database.Rpc("get_question")

func _response(msg):
	print(msg)

func _error(e):
	print(e)
