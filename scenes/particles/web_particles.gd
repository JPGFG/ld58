extends CPUParticles2D

var particleArray = []
var p1 : Texture2D = preload("res://assets/art/particleFX/web-particle-1.png")
var p2 : Texture2D = preload("res://assets/art/particleFX/web-particle-2.png")
var p3 : Texture2D = preload("res://assets/art/particleFX/web-particles-03.png")
var p4 : Texture2D = preload("res://assets/art/particleFX/web-particles-04.png")


func _ready():
	particleArray.append(p1)
	particleArray.append(p2)
	particleArray.append(p3)
	particleArray.append(p4)
	texture = particleArray[randi_range(0, particleArray.size() - 1)]
