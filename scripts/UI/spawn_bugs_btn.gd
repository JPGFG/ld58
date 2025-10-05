extends Button

signal spawn_critters
@onready var click_sound = $ClickSoundAudioStream

func _on_pressed() -> void:
	click_sound.play()
	emit_signal("spawn_critters")
