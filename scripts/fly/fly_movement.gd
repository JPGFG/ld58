extends CharacterBody2D

@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"
@export_enum("Standard", "Fleeing") var movement_type: String = "Standard"
@onready var buzz_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var speed: float = 100.0        # Horizontal speed (pixels/sec)
@export var amplitude: float = 50.0     # How tall the wave is
@export var frequency: float = 2.0      # How many waves per second

var is_caught: bool = false
var start_pos : Vector2
var time_passed: float = 0.0
var spawn_point: Vector2
var emit_fly_away_signal = true

func _ready() -> void:
	start_pos = position
	if buzz_sound.stream != null:
		buzz_sound.play()

func _physics_process(delta: float) -> void:
	if is_caught:
		wiggle(delta)
		return
	time_passed += delta
	if movement_type == "Standard":
		if movement_axis == "Vertical":
			move_vertical(delta)
		elif movement_axis == "Horizontal":
			move_horizontal(delta)
	elif movement_type == "Fleeing":
		fly_away(delta)
	
	handle_collision(move_and_collide(Vector2()))

func handle_collision(collision: KinematicCollision2D):
	if collision != null:
		var collider = collision.get_collider()
		if collider.is_in_group("anchor"):
			movement_type = "Fleeing"

func set_movment_direction(axis : String):
	movement_axis = axis

func move_horizontal(delta: float):
	# move left→right, sine wave in Y
	var new_x = position.x + speed * delta
	var new_y = start_pos.y + sin(time_passed * frequency * TAU) * amplitude
	position = Vector2(new_x, new_y)

func move_vertical(delta: float):
	# move top→bottom, sine wave in X
	var new_x = start_pos.x + sin(time_passed * frequency * TAU) * amplitude
	var new_y = position.y + speed * delta
	position = Vector2(new_x, new_y)

signal fly_fly_away(fly1)

func fly_away(delta: float):
	$CollisionShape2D.disabled = true
	if emit_fly_away_signal:
		fly_fly_away.emit(self)
		emit_fly_away_signal = false
		
	if movement_axis == "Vertical":
		$Sprite2D.flip_v = true
		var new_y = position.y + - (2 * speed) * delta
		scale = scale + Vector2(.05, .05)
		position.y = new_y
	elif movement_axis == "Horizontal":
		$Sprite2D.flip_h = true
		var new_x = position.x + - (2 * speed) * delta
		scale = scale + Vector2(.05, .05)
		position.x = new_x

signal fly_caught_in_web(fly1)

func caught_in_web():
	is_caught = true
	$CollisionShape2D.disabled = true
	fly_caught_in_web.emit(self)

func wiggle(delta: float) -> void:
	# Freeze fly in place but wiggle a little side-to-side
	buzz_sound.pitch_scale = 1.5
	var wiggle_strength = 20
	var wiggle_speed = 2
	position.x += sin(Time.get_ticks_msec() / 100.0 * wiggle_speed) * wiggle_strength * delta

func set_spawn_point(p : Vector2):
	spawn_point = p
