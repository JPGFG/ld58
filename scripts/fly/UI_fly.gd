extends Sprite2D

@export var anim : AnimationPlayer


func _ready():
	await get_tree().create_timer(6).timeout
	anim.play("fly")
	await get_tree().create_timer(16).timeout
	replay()

func replay():
	anim.play("fly")
	await get_tree().create_timer(16).timeout
	replay()
