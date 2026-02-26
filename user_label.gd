extends Label



func _ready() -> void:
	self.text = str(Supabase.auth.client)
