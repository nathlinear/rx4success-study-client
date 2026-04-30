extends Button

func _ready() -> void:
	self.pressed.connect(_toggle)

func _toggle() -> void:
	if Global.theme_setting == Global.DARK:
		Global.theme_setting = Global.LIGHT
		Global._apply_theme()
	else:
		Global.theme_setting = Global.DARK
		Global._apply_theme()
