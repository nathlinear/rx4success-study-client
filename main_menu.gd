extends Node2D


@export var quiz_button: Button
@export var stats_button: Button
@export var logout_button: Button

func _ready() -> void:
	print(Supabase.auth.client)
	quiz_button.pressed.connect(_go_to_quiz)
	stats_button.pressed.connect(_get_question)
	logout_button.pressed.connect(_logout)
	
	Supabase.database.rpc_completed.connect(_response)
	Supabase.database.error.connect(_error)
	show_username()

func _go_to_quiz():
	get_tree().change_scene_to_file("res://quiz.tscn")

func _get_question():
	Supabase.database.Rpc("get_question")

func _logout():
	var task: AuthTask = Supabase.auth.sign_out()
	await task.completed
	get_tree().change_scene_to_file("res://login.tscn")

func _response(msg: Dictionary):
	print(msg)
	print(msg.get("name"))

func _error(e):
	print(e)

func show_username() -> void:
	var label = $CanvasLayer/Control/MarginContainer/VBoxContainer/Label
	label.text = "Logged in as: %s" % await get_username()

func get_username() -> String:
	if Supabase.auth.client == null:
		return "Not logged in"
	
	var query = SupabaseQuery.new().from("user_profiles").select(["username"])
	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed
	if task.data != null and not task.data.is_empty():
		return str(task.data[0].username)
	return ""
