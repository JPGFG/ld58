extends Node2D

@onready var score_label: Label = $CanvasLayer/ScoreLabel
var score: int = 0

func _ready() -> void:
	update_score_display()

func add_score(amount: int = 1) -> void:
	score += amount
	update_score_display()

func update_score_display() -> void:
	score_label.text = "Score: %d" % score
