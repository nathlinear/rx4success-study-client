extends Node2D

@export var quiz_button: Button
@export var stats_button: Button
@export var logout_button: Button

func _ready() -> void:
	print("MAIN MENU READY: client = ", Supabase.auth.client)

	if not quiz_button.pressed.is_connected(_go_to_quiz):
		quiz_button.pressed.connect(_go_to_quiz)

	if not stats_button.pressed.is_connected(_get_question):
		stats_button.pressed.connect(_get_question)

	if not logout_button.pressed.is_connected(_logout):
		logout_button.pressed.connect(_logout)
	
	if not Supabase.database.rpc_completed.is_connected(_response):
		Supabase.database.rpc_completed.connect(_response)

	if not Supabase.database.error.is_connected(_error):
		Supabase.database.error.connect(_error)

	show_username()

func _go_to_quiz() -> void:
	get_tree().change_scene_to_file("res://quiz.tscn")

func _get_question() -> void:
	Supabase.database.Rpc("get_question")

func _logout() -> void:
	logout_button.disabled = true
	print("LOGOUT: before sign out, client = ", Supabase.auth.client)

	var task: AuthTask = Supabase.auth.sign_out()
	await task.completed

	print("LOGOUT: after sign out, client = ", Supabase.auth.client)

	await get_tree().process_frame
	get_tree().change_scene_to_file("res://login.tscn")

func _response(msg: Dictionary) -> void:
	print(msg)
	print(msg.get("name"))

func _error(e) -> void:
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
