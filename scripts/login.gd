extends Node2D

@export var email_field: LineEdit
@export var pass_field: LineEdit
@export var login_button: Button
@export var info: RichTextLabel
@export var register_button: Button
@export var passwordVBox: VBoxContainer
@export var usernameVBox: VBoxContainer
@export var createUsernameButton: Button
@export var createUsernameField: LineEdit
@export var consentCheckBox: CheckBox

func _ready() -> void:
	# connect buttons
	login_button.pressed.connect(sign_in)
	register_button.pressed.connect(sign_up)

	# connect signals
	Supabase.auth.signed_in.connect(_on_signed_in)
	Supabase.auth.error.connect(_auth_error)
	Supabase.database.inserted.connect(_on_inserted)
	Supabase.database.selected.connect(_on_selected)
	Supabase.database.error.connect(_db_error)

	# username creation UI starts hidden
	passwordVBox.visible = true
	usernameVBox.visible = false

	# disable create username button until fields are valid
	createUsernameButton.disabled = true

	# update button state whenever input changes
	createUsernameField.text_changed.connect(_update_create_username_button)
	consentCheckBox.toggled.connect(_update_create_username_button)

func _on_signed_in(user : SupabaseUser):
	print("Successfully signed as ", user)
	var username = await get_username()
	if username != "":
		load_menu()
		return

	var success = await make_username()

	if success:
		load_menu()
		return
	else:
		passwordVBox.visible = true
		usernameVBox.visible = false
		Supabase.auth.sign_out()

func _on_signed_out() -> void:
	print("Signed out")

func _on_inserted(result: Array) -> void:
	print(result)

func _on_selected(result: Array) -> void:
	print(result)
	if Supabase.auth.client == null:
		print("Not logged in!")
	print(Supabase.auth.client)

func _db_error(e: SupabaseDatabaseError) -> void:
	if e.message.begins_with("duplicate"):
		info.text = "Username already taken."
	else:
		info.text = e.message

func _auth_error(e: SupabaseAuthError):
	print(e.message)
	info.text = e.message

func load_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

func sign_in():
	var task: AuthTask = Supabase.auth.sign_in(email_field.text, pass_field.text)
	await task.completed
	if task.error:
		print(task.error.message)
		info.text = task.error.message

func sign_up():
	var task: AuthTask = Supabase.auth.sign_up(email_field.text, pass_field.text)
	await task.completed
	if task.error:
		print(task.error.message)
		info.text = task.error.message
	else:
		sign_in()

func has_username() -> bool:
	return true

func make_username() -> bool:
	usernameVBox.visible = true
	passwordVBox.visible = false
	createUsernameField.text = ""
	consentCheckBox.button_pressed = false
	_update_create_username_button()

	while true:
		await createUsernameButton.pressed

		var username: String = createUsernameField.text.strip_edges()

		if username.length() < 1:
			info.text = "Username cannot be blank."
			print("username cannot be blank. try again")
			continue

		if not consentCheckBox.button_pressed:
			info.text = "You must agree before continuing."
			print("consent not checked")
			continue

		await insert_username(username)
		var res = await get_username()
		print(res == "")
		if res != "":
			break

	return true

func get_username() -> String:
	var query = SupabaseQuery.new().from("user_profiles").select(["username"])
	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed
	if task.data != null and not task.data.is_empty():
		return str(task.data[0].username)
	return ""

func login() -> void:
	Supabase.auth.sign_in("a@u.pacific.edu", "your-password")

func logout() -> void:
	Supabase.auth.sign_out()

func insert_username(username: String) -> void:
	var query = (
		SupabaseQuery.new()
		.from("user_profiles")
		.insert(
			[{"username": username}]
		)
	)
	var task = Supabase.database.query(query)
	await task.completed

func _update_create_username_button(_arg = null) -> void:
	var username_ok = createUsernameField.text.strip_edges().length() > 0
	var consent_ok = consentCheckBox.button_pressed
	createUsernameButton.disabled = not (username_ok and consent_ok)
