extends Node2D

var worm_scene : PackedScene
@export var spawn_interval: float = 2.0   # seconds between spawns
@export var max_worms: int = 10           # optional limit
@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"

var spawn_timer: float = 0.0

# List of flies we can pull from when we catch them in the web
var active_worms: Array = []

func _ready() -> void:
	worm_scene = preload("res://scenes/fly.tscn")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and (max_worms == 0 or active_worms.size() < max_worms):
		spawn_timer = 0.0
		spawn_worm()

func spawn_worm() -> void:
	if worm_scene == null:
		return
	
	var worm = worm_scene.instantiate()
	# spawn at spawner’s position
	worm.position = global_position   
	# or get_parent().add_child(worm) if you want them in the level root
	# added them as children for now
	add_child(worm)
	
	# Function that lives in the fly script itself
	worm.set_movment_direction(movement_axis)
	
	active_worms.append(worm)

	# Cleanup when flies are freed
	# Basically if we later delete the node from the scene this will erase it from the array
	# so we don't get an exception
	worm.tree_exited.connect(func(): active_worms.erase(worm))
