extends Node2D

#@export var bugs: Array[PackedScene]
var fly_scene : PackedScene
@export var spawn_interval: float = 2.0   # seconds between spawns
@export var max_flies: int = 10           # optional limit
@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"

var spawn_timer: float = 0.0
var active_flies: Array = []

func _ready() -> void:
	fly_scene = preload("res://scenes/fly.tscn")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and (max_flies == 0 or active_flies.size() < max_flies):
		spawn_timer = 0.0
		spawn_fly()

func spawn_fly() -> void:
	if fly_scene == null:
		return
	
	var fly = fly_scene.instantiate()
	fly.position = global_position   # spawn at spawner’s position
	add_child(fly)                   # or get_parent().add_child(fly) if you want them in the level root

	fly.set_movment_direction(movement_axis)
	
	active_flies.append(fly)

	# Cleanup when flies are freed
	fly.tree_exited.connect(func(): active_flies.erase(fly))
