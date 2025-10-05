extends Control

@export var rotate_speed := 0.05
var initialRotation : float

func _ready():
	initialRotation = rotation_degrees

func _physics_process(delta):
	rotation += rotate_speed * delta
	if rotation_degrees > initialRotation + 2.5 or rotation_degrees < initialRotation - 2.5:
		rotate_speed = rotate_speed * -1
	if rotate_speed < 0:
		scale -= (abs(rotate_speed * 2) * delta) * Vector2.ONE
	if rotate_speed > 0:
		scale += (abs(rotate_speed * 2) * delta) * Vector2.ONE
