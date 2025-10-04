extends Area2D

var scoreboard : Node2D

func _ready() -> void:
	scoreboard = $"../ScoreController"

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("worms"):
		body.caught_in_web()
		#scoreboard.add_score()
