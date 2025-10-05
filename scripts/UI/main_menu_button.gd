extends Button


@export var scrollSound: AudioStreamPlayer2D
@export var clickSound: AudioStreamPlayer2D


func _on_pressed():
	clickSound.play()
	
