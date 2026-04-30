extends Node2D

@export var quiz_button: Button
@export var custom_quiz_button: Button
@export var stats_button: Button
@export var leaderboard_btn: Button
@export var account_btn: Button
@export var logout_button: Button
@export var username_label: Label

func _ready() -> void:
	
	
	print("MAIN MENU READY: client = ", Supabase.auth.client)

	if not quiz_button.pressed.is_connected(_go_to_quiz):
		quiz_button.pressed.connect(_go_to_quiz)

	if not custom_quiz_button.pressed.is_connected(_go_to_custom_quiz_setup):
		custom_quiz_button.pressed.connect(_go_to_custom_quiz_setup)

	if not stats_button.pressed.is_connected(_go_to_stats):
		stats_button.pressed.connect(_go_to_stats)

	if not leaderboard_btn.pressed.is_connected(_go_to_leaderboard):
		leaderboard_btn.pressed.connect(_go_to_leaderboard)
	
	if not account_btn.pressed.is_connected(_go_to_account):
		account_btn.pressed.connect(_go_to_account)

	if not logout_button.pressed.is_connected(_logout):
		logout_button.pressed.connect(_logout)

	if not Supabase.database.rpc_completed.is_connected(_response):
		Supabase.database.rpc_completed.connect(_response)

	if not Supabase.database.error.is_connected(_error):
		Supabase.database.error.connect(_error)

	show_username()

func _go_to_quiz() -> void:
	get_tree().change_scene_to_file("res://scenes/quiz.tscn")

func _go_to_custom_quiz_setup() -> void:
	get_tree().change_scene_to_file("res://scenes/custom_quiz_setup.tscn")

func _go_to_stats() -> void:
	get_tree().change_scene_to_file("res://scenes/stats.tscn")

func _go_to_leaderboard() -> void:
	get_tree().change_scene_to_file("res://scenes/leaderboards.tscn")

func _go_to_account() -> void:
	get_tree().change_scene_to_file("res://scenes/account.tscn")

func _logout() -> void:
	logout_button.disabled = true
	print("LOGOUT: before sign out, client = ", Supabase.auth.client)

	var task: AuthTask = Supabase.auth.sign_out()
	await task.completed

	print("LOGOUT: after sign out, client = ", Supabase.auth.client)

	await get_tree().process_frame

	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload();")
	else:
		get_tree().change_scene_to_file("res://scenes/login.tscn")

func _response(msg) -> void:
	print(msg)

func _error(e) -> void:
	print(e)

func show_username() -> void:
	username_label.text = "Logged in as: %s" % await get_username()

func get_username() -> String:
	if Supabase.auth.client == null:
		return "Not logged in"

	var query = SupabaseQuery.new().from("user_profiles").select(["username"])
	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed

	if task.data != null and not task.data.is_empty():
		return str(task.data[0].username)

	return ""
