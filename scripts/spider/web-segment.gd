class_name WebSegment
extends Line2D

@export var thickness := 8.0

var parent: Node2D

signal stitch_changed(new_count: int)
signal web_broken

var baseTensileStrength := 2
var tensileStrength := 2

var start_point: Vector2
var end_point: Vector2
var global_length: float

var area: Area2D
var collider: CollisionShape2D

var caughtObjects = []
var stitches := {}
var _breaking := false

var scoreboard : Node2D

func _init(start: Vector2, end: Vector2, par:Node2D) -> void:
	start_point = start
	end_point = end
	global_length = start_point.distance_to(end_point)
	parent = par

func _ready() -> void:
	# Ensure children exist
	area = Area2D.new()
	add_child(area)
	collider = CollisionShape2D.new()
	area.add_child(collider)
	
	area.monitoring = true
	area.monitorable = true
	area.add_to_group("web")
	
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	if not area.area_entered.is_connected(_on_area_entered):
		area.area_entered.connect(_on_area_entered)
	if not area.area_exited.is_connected(_on_area_exited):
		area.area_exited.connect(_on_area_exited)

	# Geometry
	var dir := end_point - start_point
	var length := dir.length()
	if length < 1.0:
		queue_free()
		return
	var ang := dir.angle()
	var mid := (start_point + end_point) * 0.5

	# Place/rotate THIS node; keep everything else in local space
	global_position = mid
	global_rotation = ang

	# Draw the line in LOCAL coords (centered)
	points = PackedVector2Array([
		Vector2(-length * 0.5, 0),
		Vector2( length * 0.5, 0),
	])
	
	# Collider: rectangle sized to the segment (LOCAL)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, max(thickness, 1.0))
	# Make the shape instance-local to avoid accidental sharing
	rect.resource_local_to_scene = true
	collider.shape = rect
	collider.position = Vector2.ZERO
	scoreboard = $"../../ScoreController" # needs elegance
	# Area layers/masks so it only overlaps what you want
	# area.collision_layer = 1 << 6
	# area.collision_mask  = (1 << 6)  # web↔web; add others if needed

func _on_area_entered(other_area: Area2D) -> void:
	if not is_instance_valid(other_area): return
	var other := other_area.get_parent() as WebSegment
	if other == null or other == self: return
	
	var id := other.get_instance_id()
	stitches[id] = 1.0
	_recompute_strength()
	other._register_stitch_from(self)

func _on_area_exited(other_area: Area2D) -> void:
	if not is_instance_valid(other_area): return
	var other:= other_area.get_parent() as WebSegment
	if other == null: return
	stitches.erase(other.get_instance_id())
	_recompute_strength()
	other._unregister_stitch_from(self)


func _register_stitch_from(other: WebSegment) -> void:
	if other == null: return
	stitches[other.get_instance_id()] = 1.0
	_recompute_strength()

func _unregister_stitch_from(other: WebSegment) -> void:
	if other == null: return
	stitches.erase(other.get_instance_id())
	_recompute_strength()

func _recompute_strength() -> void:
	tensileStrength = baseTensileStrength + stitches.size()
	emit_signal("stitch_changed", stitches.size())

func break_with_overload() -> void:
	if _breaking: return
	_breaking = true
	area.set_deferred("monitoring", false)
	area.set_deferred("monitorable", false)
	
	await get_tree().process_frame
	
	var neighbor_ids := stitches.keys()
	for id in neighbor_ids:
		if is_instance_id_valid(id):
			var other := instance_from_id(id) as WebSegment
			if is_instance_valid(other):
				other._unregister_stitch_from(self)
	stitches.clear()
	tensileStrength = baseTensileStrength
	emit_signal("stitch_changed", 0)
	emit_signal("web_broken")
	
	for b in caughtObjects.duplicate():
		if is_instance_valid(b):
			b.breakout()
			
	
	call_deferred("queue_free")

func remove_by_player() -> void:
	if _breaking: return
	_breaking = true
	
	area.set_deferred("monitoring", false)
	area.set_deferred("monitorable", false)
	
	var ids:= stitches.keys()
	for id in ids:
		if is_instance_id_valid(id):
			var other := instance_from_id(id) as WebSegment
			if is_instance_valid(other):
				other._unregister_stitch_from(self)
	
	stitches.clear()
	tensileStrength = baseTensileStrength
	stitch_changed.emit(0)
	web_broken.emit()
	
	call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("flies"):
		body.caught_in_web()
		caughtObjects.append(body)
		if caughtObjects.size() >= tensileStrength and not _breaking:
			call_deferred("break_with_overload")

func _exit_tree() -> void:
	for id in stitches.keys():
		if is_instance_id_valid(id):
			var other := instance_from_id(id) as WebSegment
			if is_instance_valid(other):
				other._unregister_stitch_from(self)
	stitches.clear()
