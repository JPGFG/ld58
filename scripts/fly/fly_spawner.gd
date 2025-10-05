extends Node2D

var fly_scene : PackedScene
@export var spawn_interval: float = 2.0   # seconds between spawns
@export var max_flies: int = 10           # optional limit
@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"

@onready var spawn_area: CollisionShape2D = $SpawnArea
var should_spawn = false
var spawn_timer: float = 0.0

# List of flies we can pull from when we catch them in the web
var active_flies: Array = []

func _ready() -> void:
	fly_scene = preload("res://scenes/fly.tscn")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if should_spawn and spawn_timer >= spawn_interval and (max_flies == 0 or active_flies.size() < max_flies):
		spawn_timer = 0.0
		spawn_fly()

func spawn_fly() -> void:
	if fly_scene == null:
		return
	
	var rect_spawn_area = get_spawn_rect()
	var random_x = randf_range(rect_spawn_area.position.x, rect_spawn_area.position.x + rect_spawn_area.size.x)
	var random_y = randf_range(rect_spawn_area.position.y, rect_spawn_area.position.y + rect_spawn_area.size.y)
	var spawn_pos = Vector2(random_x, random_y)
	var fly = fly_scene.instantiate()
	# spawn at spawner’s position
	fly.global_position = spawn_pos
	fly.set_spawn_point(spawn_pos)
	# or get_parent().add_child(fly) if you want them in the level root
	# added them as children for now
	get_parent().add_child(fly)
	
	# Function that lives in the fly script itself
	fly.set_movment_direction(movement_axis)
	
	active_flies.append(fly)

	# Cleanup when flies are freed
	# Basically if we later delete the node from the scene this will erase it from the array
	# so we don't get an exception
	fly.tree_exited.connect(func(): active_flies.erase(fly))

func get_spawn_rect() -> Rect2:
	var shape = spawn_area.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var rect_pos = global_position - extents
		var rect_size = extents * 2.0
		return Rect2(rect_pos, rect_size)
	return Rect2(global_position, Vector2.ZERO)

func enable_spawning(enabled: bool):
	should_spawn = enabled
