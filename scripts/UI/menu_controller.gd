extends Control

@onready var start_game_btn : Button = $"./MarginContainer/Column/StartGameBtn"
@onready var about_btn : Button = $"./MarginContainer/Column/AboutBtn"
@onready var options_btn : Button = $"./MarginContainer/Column/SettingsBtn"
@onready var clickSound: AudioStreamPlayer2D = $"./ClickSoundAudioStream"
@export var scrollSound: AudioStreamPlayer2D

func _ready() -> void:
	start_game_btn.pressed.connect(start_game_clicked)
	about_btn.pressed.connect(about_clicked)
	options_btn.pressed.connect(options_clicked)

func start_game_clicked():
	clickSound.play()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/level-1.tscn")
	
func about_clicked():
	clickSound.play()
	
func options_clicked():
	clickSound.play()


func _on_start_btn_pressed() -> void:
	clickSound.play()
	get_tree().change_scene_to_file("res://scenes/levels/level-1.tscn")
