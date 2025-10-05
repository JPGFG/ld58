extends Node

var level_paths = [
	"res://Scenes/UI/title_screen.tscn",
	"res://Scenes/Levels/level-1.tscn",
	"res://Scenes/Levels/level-2.tscn",
	"res://Scenes/Levels/level-3.tscn",
	"res://Scenes/Levels/level-4.tscn",
	"res://Scenes/Levels/level-5.tscn"
]

var current_level_index = 0
var current_level_scene: Node = null

func get_current_level() -> int:
	return level_paths[current_level_index]

func next_level() -> String:
	current_level_index += 1
	# If we're on the last level go back to the home screen
	if current_level_index >= level_paths.size():
		current_level_index = 0
	return level_paths[current_level_index]
