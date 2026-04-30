extends Node

func _ready() -> void:
	$Control/CenterContainer/MarginContainer/MarginContainer/Label.text = ""
	$Control/CenterContainer.modulate.a = 0.0

func show_popup(popup_text: String) -> void:
	$Control/CenterContainer/MarginContainer/MarginContainer/Label.text = popup_text
	var tween = get_tree().create_tween()
	tween.tween_property($Control/CenterContainer, "modulate:a", 1.0, 0.25)
	tween.tween_property($Control/CenterContainer, "modulate:a", 1.0, 0.5)
	tween.tween_property($Control/CenterContainer, "modulate:a", 0.0, 0.25)
