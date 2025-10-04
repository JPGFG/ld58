extends Node2D


const ANCHOR_MASK := 1

var dragging := false

var start_anchor: Node
var start_point_global: Vector2

var end_anchor: Node
var end_point_global: Vector2

var segmentList: Array = []
var totalSegmentDist: float = 0

@export var dummyUI: RichTextLabel

@export var previewLine: Line2D

func _ready():
	dummyUI.text = "Web Used: " + str(int(totalSegmentDist))

func _unhandled_input(event: InputEvent) -> void:
	
	#MOUSE DOWN - Checks for point collisions with "anchor" groups
	#This can eventually be extrapolated into a solo function.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse := get_global_mouse_position()
		
		var params := PhysicsPointQueryParameters2D.new()
		params.position = mouse
		params.collide_with_bodies = true
		params.collide_with_areas = true
		params.collision_mask = ANCHOR_MASK
		
		var hits := get_world_2d().direct_space_state.intersect_point(params, 8)
		for h in hits:
			var n := h.collider as Node
			if n and n.is_in_group("anchor"):
				start_anchor = n
				start_point_global = get_global_mouse_position()
				dragging = true
				print("HIT!")
				# Show preview Line handled in process function
				return
	
	
	# MOUSE UP - Checks current position for anchorability
	# If anchor is valid, cut preview line and bake final webline.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging:
		var mouse := get_global_mouse_position()
		
		var params:= PhysicsPointQueryParameters2D.new()
		params.position = mouse
		params.collide_with_bodies = true
		params.collide_with_areas = true
		params.collision_mask = ANCHOR_MASK
		
		var hits:= get_world_2d().direct_space_state.intersect_point(params, 8)
		for h in hits:
			var n := h.collider as Node
			if n and n.is_in_group("anchor"):
				end_anchor = n
				end_point_global = get_global_mouse_position()
				dragging = false
				print("bake!")
				bakeWeb()
		stopPreview()
		
		



func _process(delta):
	if dragging:
		previewLine.visible = true
		previewLine.points = PackedVector2Array([start_point_global, get_global_mouse_position()])

func stopPreview():
		dragging = false
		previewLine.visible = false
		previewLine.clear_points()

func bakeWeb():
	var instance = WebSegment.new(start_point_global, end_point_global)
	add_child(instance)
	segmentList.append(instance)
	totalSegmentDist += instance.global_length
	updateDummyUI()
	


func updateDummyUI():
	dummyUI.text = "Web Used: " + str(int(totalSegmentDist / 10))
