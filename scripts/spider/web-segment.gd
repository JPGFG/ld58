class_name WebSegment
extends Line2D

@export var thickness := 8.0

var start_point: Vector2
var end_point: Vector2
var global_length: float

var area: Area2D
var collider: CollisionShape2D

var scoreboard : Node2D

func _init(start: Vector2, end: Vector2) -> void:
	start_point = start
	end_point = end
	global_length = start_point.distance_to(end_point)

func _ready() -> void:
	# Ensure children exist
	area = Area2D.new()
	add_child(area)
	collider = CollisionShape2D.new()
	area.add_child(collider)
	
	area.monitoring = true
	area.monitorable = true
	
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	
	# Geometry
	var dir := end_point - start_point
	var len := dir.length()
	if len < 1.0:
		queue_free()
		return
	var ang := dir.angle()
	var mid := (start_point + end_point) * 0.5

	# Place/rotate THIS node; keep everything else in local space
	global_position = mid
	global_rotation = ang

	# Draw the line in LOCAL coords (centered)
	points = PackedVector2Array([
		Vector2(-len * 0.5, 0),
		Vector2( len * 0.5, 0),
	])

	# Collider: rectangle sized to the segment (LOCAL)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(len, max(thickness, 1.0))
	# Make the shape instance-local to avoid accidental sharing
	rect.resource_local_to_scene = true
	collider.shape = rect
	collider.position = Vector2.ZERO
	
	scoreboard = $"../../ScoreController" # needs elegance
	# Area layers/masks so it only overlaps what you want
	# area.collision_layer = 1 << 6
	# area.collision_mask  = (1 << 6)  # web↔web; add others if needed

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("flies"):
		body.caught_in_web()
		scoreboard.add_score()
