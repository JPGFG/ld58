class_name WebSegment
extends Line2D

var startPoint: Vector2
var endPoint: Vector2

var collider: Area2D

func _init(start: Vector2, end: Vector2):
	startPoint = start
	endPoint = end
	
	self.add_point(startPoint)
	self.add_point(endPoint)
