extends Node

var level_paths = [
	"res://scenes/UI/title_screen.tscn",
	"res://scenes/levels/level-1.tscn",
	"res://scenes/levels/level-2.tscn",
	"res://scenes/levels/level-3.tscn",
	"res://scenes/levels/level-4.tscn",
	"res://scenes/levels/level-5.tscn"
]

var current_level_index = 0
var current_level_scene: Node = null

var song_saved_spot = { "web_song": 0.0, "fly_song": 0.0 }

func get_current_level() -> int:
	return level_paths[current_level_index]

func next_level() -> String:
	current_level_index += 1
	# If we're on the last level go back to the home screen
	if current_level_index >= level_paths.size():
		current_level_index = 0
	return level_paths[current_level_index]


func set_song_save_spot(song: String, time: float):
	song_saved_spot[song] = time

func get_spot_for_song(song: String) -> float:
	return song_saved_spot[song]
