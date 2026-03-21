extends Node2D

@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var login_button: Button
@export var info: RichTextLabel
@export var passwordVBox: VBoxContainer
@export var usernameVBox: VBoxContainer

func _ready() -> void:
	# connect buttons
	login_button.pressed.connect(sign_in)
	
	# connect signals
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.error.connect(_error)
	
	passwordVBox.visible = true
	usernameVBox.visible = false

func sign_in():
	Supabase.auth.sign_in(email_field.text, pass_field.text)

func _error(e: SupabaseAuthError):
	print(e.message)
	info.text = e.message

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	if has_username():
		_load_menu()
		return
	
	# is true when user confirms new username creation
	var success = make_username() 
	
	if success:
		_load_menu()
		return
	else:
		# user did not want to create username or errored
		# sign out and return to initial page
		passwordVBox.visible = true
		usernameVBox.visible = false
		Supabase.auth.sign_out()

func _load_menu() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")

func has_username() -> bool:
	# TODO
	return true

func make_username() -> bool:
	# TODO
	usernameVBox.visible = true
	passwordVBox.visible = false
	return true
