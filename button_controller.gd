extends Node

@export var button1: Button
@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var status: Label

func _ready() -> void:
	if button1 == null: print("Button 1 not specified in controller!")
	if email_field == null: print("Email not specified in controller!")
	if pass_field == null: print("Pass not specified in controller!")
	if status == null: print("Status not specified in controller!")
	
	button1.pressed.connect(sign_in)

func sign_in():
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.sign_in(email_field.text, pass_field.text)

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	status.text = str(user)
