extends Button


func _ready() -> void:
	self.pressed.connect(_change_scene)

func _change_scene():
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
