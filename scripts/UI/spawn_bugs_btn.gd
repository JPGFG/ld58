extends Button

signal spawn_critters

func _on_pressed() -> void:
	emit_signal("spawn_critters")
