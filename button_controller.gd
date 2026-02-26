extends Node

@export var button1: Button
@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var status: Label
@export var get_quiz_data_button: Button
@export var quiz_data_label: RichTextLabel

func _ready() -> void:
	# connect buttons
	button1.pressed.connect(sign_in)
	get_quiz_data_button.pressed.connect(get_data)
	
	# connect signals
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.error.connect(_error)
	Supabase.database.rpc_completed.connect(result)

func sign_in():
	Supabase.auth.sign_in(email_field.text, pass_field.text)

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	status.text = str(user)
	get_tree().change_scene_to_file("res://mainMenu.tscn")

func _error(e: SupabaseAuthError):
	_update_status(e.message)

func _update_status(msg):
	print(str(msg))
	status.text = str(msg)

func get_data() -> void:
	if Supabase.auth.client == null:
		_update_status("Not logged in")
		return
	
	Supabase.database.Rpc("get_my_quiz_answers")

func result(query_result) -> void:
	print(query_result)
	quiz_data_label.text = str(query_result)
