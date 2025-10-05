extends Node2D


const ANCHOR_MASK := 1
const UITEXT := "Web Used: "
var dragging := false

var start_anchor: Node
var start_point_global: Vector2

var end_anchor: Node
var end_point_global: Vector2

#RULES VARS
@export var maxLevelWebDistance: float
@export var maxSingleSegmentDistance: float
var validWebPlacement := true

#TRACKING VARS
var totalSegmentDist: float = 0
var segmentList: Array = []

#DUMMY UI VARS
@export var dummyPBar: ProgressBar
@export var dummyUI: RichTextLabel

@export var previewLine: Line2D
var web_phase_enabled = false
func _ready():
	unflagPreviewLine()
	dummyPBar.max_value = maxLevelWebDistance
	dummyPBar.value = maxLevelWebDistance
	dummyUI.text = UITEXT + str(int(totalSegmentDist))

func _unhandled_input(event: InputEvent) -> void:
	
	# LEFT MOUSE DOWN - Checks for point collisions with "anchor" groups
	#This can eventually be extrapolated into a solo function.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and web_phase_enabled:
		var mouse := get_global_mouse_position()
		unflagPreviewLine()
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
				# Show preview Line handled in process function
				return
	
	# RIGHT MOUSE CLICK - Deletes last placed segment, only during web phase.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and web_phase_enabled:
		if dragging:
			stopPreview()
		else:
			undo_last_segment()
	
	# LEFT MOUSE UP - Checks current position for anchorability
	# If anchor is valid, cut preview line and bake final webline.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging and web_phase_enabled:
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
				if validWebPlacement and start_anchor != end_anchor: #prevents same anchor usage
					bakeWeb()
				else:
					# Conditional Logic to populate a help message
					print("Not a valid web placement!")
		stopPreview()


@warning_ignore("unused_parameter")
func _process(delta):
	if dragging:
		var tempDistance = start_point_global.distance_to(get_global_mouse_position())
		if segmentList.is_empty():
			dummyUI.text = UITEXT + str(int(tempDistance / 10))
		else:
			dummyUI.text = UITEXT + str(int((totalSegmentDist + tempDistance) / 10))
		
		if ((totalSegmentDist + tempDistance) > maxLevelWebDistance) or tempDistance > maxSingleSegmentDistance:
			flagPreview()
		else:
			unflagPreviewLine()
		previewLine.visible = true
		previewLine.points = PackedVector2Array([start_point_global, get_global_mouse_position()])

func stopPreview():
	dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))
	dragging = false
	previewLine.visible = false
	previewLine.clear_points()

func bakeWeb():
	var seg = WebSegment.new(start_point_global, end_point_global, self)
	var cb := Callable(self, "_on_segment_stitch_changed").bind(seg)
	if not seg.stitch_changed.is_connected(cb):
		seg.stitch_changed.connect(cb)
	add_child(seg)

	
	segmentList.append(seg)
	totalSegmentDist += seg.global_length
	updateDummyUI()

func _on_segment_stitch_changed(count: int, seg: WebSegment) -> void:
	pass # When a stitch arrangement changes

func undo_last_segment() -> void:
	if segmentList.is_empty():
		return
	var seg: WebSegment = segmentList.pop_back()
	
	totalSegmentDist = max(0.0, totalSegmentDist - seg.global_length)
	dummyPBar.value = clamp(dummyPBar.value + seg.global_length, 0.0, maxLevelWebDistance)
	dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))
	
	seg.remove_by_player()
	

func updateDummyUI():
	var lastPlacement = start_point_global.distance_to(end_point_global)
	dummyPBar.value = dummyPBar.value - lastPlacement
	if dummyPBar.value < 50:
		dummyPBar.value = 0
	dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))

func flagPreview():
	previewLine.default_color = Color.RED
	validWebPlacement = false
func unflagPreviewLine():
	previewLine.default_color = Color.WHITE
	validWebPlacement = true

func enable_web_system(enabled : bool):
	web_phase_enabled = enabled
