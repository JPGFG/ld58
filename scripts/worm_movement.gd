extends CharacterBody2D

@export_enum("Horizontal", "Vertical") var movement_axis: String = "Horizontal"
@export var speed: float = 100.0

var is_caught: bool = false
var start_pos : Vector2
var worm_shape: Shape2D

func _ready() -> void:
	start_pos = position
	var collision_shape = $CollisionShape2D
	worm_shape = collision_shape.shape
	
func _physics_process(delta: float) -> void:
	if is_caught:
		wiggle(delta)
		return
	if movement_axis == "Vertical":
		move_vertical(delta)
	elif movement_axis == "Horizontal":
		move_horizontal(delta)
		
func move_horizontal(delta: float):
	var new_x = position.x + speed * delta
	position = Vector2(new_x, 0)

func move_vertical(delta: float):
	var new_y = position.y + -speed * delta
	position.y = new_y
	
func caught_in_web():
	is_caught = true
	
func wiggle(delta: float) -> void:
	# Freeze worm in place but wiggle a little side-to-side
	var wiggle_strength = 20
	var wiggle_speed = 2
	position.x += sin(Time.get_ticks_msec() / 100.0 * wiggle_speed) * wiggle_strength * delta


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Get the worm's shape
	var worm_shape = get_node("CollisionShape2D").shape as RectangleShape2D
	var worm_half_width = worm_shape.size.x / 2
	var worm_half_height = worm_shape.size.y / 2
	var worm_center = global_position

	# Worm corners
	var worm_top_left = Vector2(worm_center.x - worm_half_width, worm_center.y - worm_half_height)
	var worm_top_right = Vector2(worm_center.x + worm_half_width, worm_center.y - worm_half_height)
	var worm_bottom_left = Vector2(worm_center.x - worm_half_width, worm_center.y + worm_half_height)
	var worm_bottom_right = Vector2(worm_center.x + worm_half_width, worm_center.y + worm_half_height)

	# anchor shape
	var anchor_shape = body.get_node("CollisionShape2D").shape as RectangleShape2D
	var anchor_half_width = anchor_shape.size.x / 2
	var anchor_half_height = anchor_shape.size.y / 2
	var anchor_center = body.global_position
	# anchor edges
	var anchor_left = anchor_center.x - anchor_half_width
	var anchor_right = anchor_center.x + anchor_half_width
	var anchor_top = anchor_center.y - anchor_half_height
	var anchor_bottom = anchor_center.y + anchor_half_height

	# if the worm's top is above the anchor's top start horizontal movement
	if worm_top_left.y <= anchor_top and worm_top_right.y <= anchor_top:
		movement_axis = "Horizontal"

	# if the worm is within horizontal bounds of the anchor, and hits vertical bounds go vertical
	elif (worm_bottom_left.x <= anchor_right and worm_bottom_right.x >= anchor_left) and worm_bottom_left.y >= anchor_top:
		movement_axis = "Vertical"
		
	#if body.is_in_group("anchor"):
		#movement_axis = "Vertical"
	
