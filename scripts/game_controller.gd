extends Node2D

enum GameState { SPIN_WEB, SPAWN_CRITTERS, SHOW_SCORE, NEXT_LEVEL }

var state: GameState = GameState.SPIN_WEB

@onready var web_tool = $"../N2D_WebTool"
@onready var spawner = $"../FlySpawner"
@onready var scoreboard = $"../ScoreController"
@export var spawn_critters_btn: Button

var captured: Array
var flying_away: Array 
var total_flies = -1

func _ready() -> void:
	captured = []
	flying_away = []
	enter_state(GameState.SPIN_WEB)
	spawn_critters_btn.spawn_critters.connect(func(): enter_state(GameState.SPAWN_CRITTERS))
	scoreboard.restart_level.connect(func(): get_tree().reload_current_scene())
	scoreboard.next_level.connect(func(): enter_state(GameState.NEXT_LEVEL))
	
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# check to see that we have set the number of flies and that we're in the right state
	if total_flies != -1 and state == GameState.SPAWN_CRITTERS:
		if (captured.size() + flying_away.size()) == total_flies:
			enter_state(GameState.SHOW_SCORE)

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
	scoreboard.show_scoreboard(false)
	
func start_critter_spawn_phase():
	print("spawn enemies")
	spawn_critters_btn.visible = false
	web_tool.enable_web_system(false)
	spawner.enable_spawning(true)

func show_score_phase():
	await get_tree().create_timer(3.0).timeout
	scoreboard.show_scoreboard(true)
	scoreboard.set_score(captured.size(), flying_away.size())
	
func go_to_next_level():
	get_tree().change_scene_to_file(GameData.next_level())

func update_fly_data(f: Node, type: String):
	match type:
		"caught":
			captured.append(f)
		"fleeing":
			if captured.has(f):
				captured.erase(f)
			flying_away.append(f)
	
func set_total_flies(t: int):
	total_flies = t
