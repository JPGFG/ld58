extends CharacterBody2D

@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"
@export var speed: float = 100.0

var is_caught: bool = false
var start_pos : Vector2

func _ready() -> void:
	start_pos = position
	
func _physics_process(delta: float) -> void:
	if is_caught:
		wiggle(delta)
		return
	if movement_axis == "Vertical":
		move_vertical(delta)
	elif movement_axis == "Horizontal":
		move_horizontal(delta)
		
func move_horizontal(delta: float):
	var new_x = position.x + speed * delta
	position = Vector2(new_x, 0)

func move_vertical(delta: float):
	# move top→bottom, sine wave in X
	var new_y = position.y + -speed * delta
	#velocity = Vector2(0, 5)
	#position = Vector2(position.x, new_y)
	position.y = new_y
	
func caught_in_web():
	is_caught = true
	
func wiggle(delta: float) -> void:
	# Freeze worm in place but wiggle a little side-to-side
	var wiggle_strength = 20
	var wiggle_speed = 2
	position.x += sin(Time.get_ticks_msec() / 100.0 * wiggle_speed) * wiggle_strength * delta


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("anchor"):
		movement_axis = "Vertical"
