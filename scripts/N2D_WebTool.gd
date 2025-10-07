extends Node2D

# SFX Variables
var placeWebSFX: AudioStream = preload("res://assets/sounds/web-set.wav")
var breakWebSFX: AudioStream = preload("res://assets/sounds/web-overload.wav")
var cancelWebSFX: AudioStream = preload("res://assets/sounds/cancel-web.wav")
var dragWebLoopSFX: AudioStream = preload("res://assets/sounds/web-pull.wav")
var reinforceSFX: AudioStream = preload("res://assets/sounds/web-overload.wav")
var _nodule_by_pair := {}  # key: Vector2i(low, high) → Node2D

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

#Ui Controlls
@export var web_meter_panel: Panel
var webProgressBar: ProgressBar

@export var previewLine: Line2D
var web_phase_enabled = false
func _ready():
	webProgressBar = web_meter_panel.get_node("WebRemainingBar")
	unflagPreviewLine()
	webProgressBar.max_value = maxLevelWebDistance
	webProgressBar.value = maxLevelWebDistance
	
	for i in 8:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Master"
		p.attenuation = 1.0
		add_child(p)
		_sfx_pool.append(p)
	_drag_player.bus = "Master"
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
		#if segmentList.is_empty():
			#dummyUI.text = UITEXT + str(int(tempDistance / 10))
		#else:
			#dummyUI.text = UITEXT + str(int((totalSegmentDist + tempDistance) / 10))
		
		if ((totalSegmentDist + tempDistance) > maxLevelWebDistance) or tempDistance > maxSingleSegmentDistance:
			flagPreview()
		else:
			unflagPreviewLine()
		previewLine.visible = true
		previewLine.points = PackedVector2Array([start_point_global, get_global_mouse_position()])

func stopPreview():
	#dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))
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
	seg.stitch_added.connect(_on_stitch_added)
	seg.stitch_removed.connect(_on_stitch_removed)
	play_sfx_at(placeWebSFX, seg.position)

	
	segmentList.append(seg)
	totalSegmentDist += seg.global_length
	updateDummyUI()

@warning_ignore("unused_parameter")
func _on_segment_stitch_changed(count: int, seg: WebSegment) -> void:
	# do your UI/tension updates here
	pass

func _pair_key(low_id:int, high_id:int) -> Vector2i:
	return Vector2i(low_id, high_id)

func _on_stitch_added(pos: Vector2, low_id:int, high_id:int) -> void:
	var key := _pair_key(low_id, high_id)
	if _nodule_by_pair.has(key): return
	var node := _spawn_nodule(pos)  # see below
	_nodule_by_pair[key] = node
	play_sfx_at(reinforceSFX, pos)

func _on_stitch_removed(low_id:int, high_id:int) -> void:
	var key := _pair_key(low_id, high_id)
	if not _nodule_by_pair.has(key): return
	var node: Node2D = _nodule_by_pair[key]
	_nodule_by_pair.erase(key)
	_fade_and_free(node)

func undo_last_segment() -> void:
	if segmentList.is_empty():
		return
	
	var seg: WebSegment = segmentList.pop_back()
	play_sfx_at(cancelWebSFX, seg.position)
	totalSegmentDist = max(0.0, totalSegmentDist - seg.global_length)
	webProgressBar.value = clamp(webProgressBar.value + seg.global_length, 0.0, maxLevelWebDistance)
	#dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))
	
	seg.remove_by_player()
	

func updateDummyUI():
	var lastPlacement = start_point_global.distance_to(end_point_global)
	webProgressBar.value = webProgressBar.value - lastPlacement
	if webProgressBar.value < 50:
		webProgressBar.value = 0
	#dummyUI.text = UITEXT + str(int(totalSegmentDist / 10))

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


func _spawn_nodule(pos:Vector2) -> Node2D:
	var n := Node2D.new()
	n.global_position = pos
	add_child(n)
	
	var s:= Sprite2D.new()
	s.texture = preload("res://assets/art/web-nodule.png")
	s.centered = true
	s.modulate = Color.WHITE
	n.add_child(s)
	
	n.scale = Vector2(0.1, 0.1)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE * 2, 0.15)
	
	return n

func _fade_and_free(n: Node2D) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "modulate:a", 0.0, 0.12)
	tw.tween_callback(n.queue_free)
	
	
func flagPreview():
	previewLine.default_color = Color.RED
	validWebPlacement = false
func unflagPreviewLine():
	previewLine.default_color = Color.WHITE
	validWebPlacement = true

func enable_web_system(enabled : bool):
	web_phase_enabled = enabled
