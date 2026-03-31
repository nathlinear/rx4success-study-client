extends ScrollContainer


func _ready() -> void:

	var scroll: VScrollBar = get_v_scroll_bar()
	scroll.custom_minimum_size = Vector2(20, 0)
