extends Node2D

enum GameState { SPIN_WEB, SPAWN_CRITTERS, SHOW_SCORE, NEXT_LEVEL }

var state: GameState = GameState.SPIN_WEB

@onready var web_tool = $"../N2D_WebTool"
@onready var spawner = $"../FlySpawner"
@export var spawn_critters_btn: Button


func _ready() -> void:
	enter_state(GameState.SPIN_WEB)
	spawn_critters_btn.spawn_critters.connect(func(): enter_state(GameState.SPAWN_CRITTERS))
	
func enter_state(new_state: GameState) -> void:
	state = new_state
	match state:
		GameState.SPIN_WEB:
			start_web_phase()
		GameState.SPAWN_CRITTERS:
			start_critter_spawn_phase()
		GameState.SHOW_SCORE:
			show_score_phase()
		GameState.NEXT_LEVEL:
			go_to_next_level()

func start_web_phase():
	print("web stage")
	web_tool.enable_web_system(true)
	
func start_critter_spawn_phase():
	print("spawn enemies")
	spawn_critters_btn.visible = false
	web_tool.enable_web_system(false)
	spawner.enable_spawning(true)

func show_score_phase():
	print("show score")
	
func go_to_next_level():
	print("next level")
