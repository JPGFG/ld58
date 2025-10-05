extends Node2D

# SFX Variables
var placeWebSFX: AudioStream = preload("res://assets/sounds/web-set.wav")
var breakWebSFX: AudioStream = preload("res://assets/sounds/web-overload.wav")
var cancelWebSFX: AudioStream = preload("res://assets/sounds/cancel-web.wav")
var dragWebLoopSFX: AudioStream = preload("res://assets/sounds/web-pull.wav")

var _sfx_pool: Array[AudioStreamPlayer2D] = []
@onready var _drag_player := AudioStreamPlayer2D.new()

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
	
	for i in 8:
		var p := AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.attenuation = 1.0
		add_child(p)
		_sfx_pool.append(p)
	_drag_player.bus = "SFX"
	_drag_player.stream = dragWebLoopSFX
	_drag_player.autoplay = false
	_drag_player.volume_db = 5.0
	add_child(_drag_player)

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
		start_drag_sfx()
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
	stop_drag_sfx()

func bakeWeb():
	var seg = WebSegment.new(start_point_global, end_point_global, self)
	var cb := Callable(self, "_on_segment_stitch_changed").bind(seg)
	if not seg.stitch_changed.is_connected(cb):
		seg.stitch_changed.connect(cb)
	add_child(seg)
	play_sfx_at(placeWebSFX, seg.position)

	
	segmentList.append(seg)
	totalSegmentDist += seg.global_length
	updateDummyUI()

func _on_segment_stitch_changed(count: int, seg: WebSegment) -> void:
	pass # When a stitch arrangement changes

func undo_last_segment() -> void:
	if segmentList.is_empty():
		return
	
	var seg: WebSegment = segmentList.pop_back()
	play_sfx_at(cancelWebSFX, seg.position)
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

func play_sfx_at(stream: AudioStream, pos: Vector2, pitch_jitter:=0.07):
	var p = _sfx_pool.pop_back()
	if p == null:
		p = AudioStreamPlayer2D.new(); add_child(p)
	p.stream = stream
	p.global_position = pos
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.finished.connect(func(): _sfx_pool.append(p), CONNECT_ONE_SHOT)
	p.play()

func start_drag_sfx():
	if dragWebLoopSFX and not _drag_player.playing:
		_drag_player.play()

func stop_drag_sfx():
	if _drag_player.playing:
		_drag_player.stop()

#func spawn_fx(scene: PackedScene, pos: Vector2):
#	if scene == null: return
#	var fx:= scene.instantiate()
#	fx.global_position = pos
#	add_child(fx)
	

func flagPreview():
	previewLine.default_color = Color.RED
	validWebPlacement = false
func unflagPreviewLine():
	previewLine.default_color = Color.WHITE
	validWebPlacement = true

func enable_web_system(enabled : bool):
	web_phase_enabled = enabled
