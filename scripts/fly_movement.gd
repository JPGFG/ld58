extends CharacterBody2D

@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"
@export var speed: float = 100.0        # Horizontal speed (pixels/sec)
@export var amplitude: float = 50.0     # How tall the wave is
@export var frequency: float = 2.0      # How many waves per second

var start_pos : Vector2
var time_passed: float = 0.0

func _ready() -> void:
	start_pos = position

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	if movement_axis == "Vertical":
		move_vertical(delta, time_passed)
	elif movement_axis == "Horizontal":
		move_horizontal(delta, time_passed)


func move_horizontal(delta: float, time_passed: float):
	# move left→right, sine wave in Y
	var new_x = position.x + speed * delta
	var new_y = start_pos.y + sin(time_passed * frequency * TAU) * amplitude
	position = Vector2(new_x, new_y)

func move_vertical(delta: float, time_passed: float):
	# move top→bottom, sine wave in X
	var new_x = start_pos.x + sin(time_passed * frequency * TAU) * amplitude
	var new_y = position.y + speed * delta
	position = Vector2(new_x, new_y)
