extends Node2D


@export var quit_button: Button

func _ready() -> void:
	quit_button.pressed.connect(_change_scene)
	
func _change_scene() -> void:
	get_tree().change_scene_to_file("res://mainMenu.tscn")
