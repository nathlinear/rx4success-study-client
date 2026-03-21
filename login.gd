extends Node2D

@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var login_button: Button
@export var info: RichTextLabel

func _ready() -> void:
	# connect buttons
	login_button.pressed.connect(sign_in)
	
	# connect signals
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.error.connect(_error)

func sign_in():
	Supabase.auth.sign_in(email_field.text, pass_field.text)

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	get_tree().change_scene_to_file("res://mainMenu.tscn")

func _error(e: SupabaseAuthError):
	print(e.message)
	info.text = e.message
