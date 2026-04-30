extends Node2D


@export var change_username_button: Button
@export var reset_level_button: Button
@export var reset_all_button: Button

@export var confirm_button: Button
@export var cancel_button: Button
@export var question_level_option: OptionButton
@export var new_username: LineEdit
@export var username_label: Label

@export var popup_container: PanelContainer

@export var vbox_username: VBoxContainer
@export var vbox_reset_level: VBoxContainer
@export var vbox_reset_all: VBoxContainer

var saved_choice

enum {
	CHANGE_USERNAME,
	RESET_LEVEL,
	RESET_ALL
}

func _ready() -> void:
	_hide_popup()
	
	cancel_button.pressed.connect(_hide_popup)
	confirm_button.pressed.connect(_confirm)
	
	change_username_button.pressed.connect(_chosen.bind(CHANGE_USERNAME))
	reset_level_button.pressed.connect(_chosen.bind(RESET_LEVEL))
	reset_all_button.pressed.connect(_chosen.bind(RESET_ALL))

func _chosen(num: int) -> void:
	saved_choice = num
	popup_container.visible = true
	
	match num:
		CHANGE_USERNAME:
			vbox_username.visible = true
		RESET_LEVEL:
			vbox_reset_level.visible = true
		RESET_ALL:
			vbox_reset_all.visible = true

func _confirm() -> void:
	
	match saved_choice:
		CHANGE_USERNAME:
			_change_username(new_username.text)
		RESET_LEVEL:
			var id = int(question_level_option.get_selected_id())
			var level = int(question_level_option.get_item_text(id))
			if level > 0:
				_reset_level(level)
		RESET_ALL:
			_reset_all()
	
	_hide_popup()

func _change_username(username: String) -> void:
	var query = (
		SupabaseQuery.new()
		.from("user_profiles")
		.update(
			{"username": username}
		).eq("id", Supabase.auth.client.id)
	)
	var task = Supabase.database.query(query)
	await task.completed

func _reset_level(level: int) -> void:
	var task = Supabase.database.Rpc("delete_quiz_answers_by_level", {"p_level": level})
	await task.completed

func _reset_all() -> void:
	var task = Supabase.database.Rpc("delete_all_quiz_answers")
	await task.completed

func _hide_popup() -> void:
	popup_container.visible = false
	vbox_username.visible = false
	vbox_reset_level.visible = false
	vbox_reset_all.visible = false
	username_label.text = "Your current username:\n" + await get_username()

func get_username() -> String:
	if Supabase.auth.client == null:
		return "Not logged in"

	var query = SupabaseQuery.new().from("user_profiles").select(["username"])
	var task: DatabaseTask = Supabase.database.query(query)
	await task.completed

	if task.data != null and not task.data.is_empty():
		return str(task.data[0].username)

	return ""
