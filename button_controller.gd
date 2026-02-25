extends Node

@export var button1: Button
@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var status: Label
@export var get_quiz_data_button: Button
@export var quiz_data_label: RichTextLabel

func _ready() -> void:
	button1.pressed.connect(sign_in)
	get_quiz_data_button.pressed.connect(get_data)

func sign_in():
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.sign_in(email_field.text, pass_field.text)

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	status.text = str(user)

func get_data() -> void:
	Supabase.database.Rpc("get_my_quiz_answers")
	
	if Supabase.database.rpc_completed.has_connections():
		return
	
	Supabase.database.rpc_completed.connect(result)

func result(query_result) -> void:
	print(query_result)
	quiz_data_label.text = str(query_result)
