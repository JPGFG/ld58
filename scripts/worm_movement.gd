extends CharacterBody2D

@export var speed: float = 100.0

var is_caught: bool = false
var start_pos : Vector2

func _ready() -> void:
	start_pos = position
	
func _physics_process(delta: float) -> void:
	if is_caught:
		wiggle(delta)
		return
	move_horizontal(delta)
		
func move_horizontal(delta: float):
	var new_x = position.x + speed * delta
	position = Vector2(new_x, 0)
	
func caught_in_web():
	is_caught = true
	
func wiggle(delta: float) -> void:
	# Freeze worm in place but wiggle a little side-to-side
	var wiggle_strength = 20
	var wiggle_speed = 2
	position.x += sin(Time.get_ticks_msec() / 100.0 * wiggle_speed) * wiggle_strength * delta
