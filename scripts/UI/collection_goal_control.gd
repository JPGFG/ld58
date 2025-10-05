extends Control

@export var target_label: Label

func set_target_collection(goal : int):
	target_label.text = "X %d" % goal
