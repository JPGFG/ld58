extends Node2D

enum GameState { SPIN_WEB, SPAWN_CRITTERS, SHOW_SCORE, NEXT_LEVEL }

var state: GameState = GameState.SPIN_WEB

@onready var web_tool = $"../N2D_WebTool"
@export var spawners: Array[Node] = []
@onready var scoreboard = $"../ScoreController"
@export var spawn_critters_btn: Button
# Number of flies that you need to catch to beat the level 
@export var goal_flies: int = 0
@onready var collection_goal_ui = $"../CollectionGoalControl"
@onready var web_phase_song = $WebPhaseAudioStream
@onready var fly_phase_song = $FlyPhaseAudioStream

var captured: Array
var flying_away: Array 
var total_flies = -1

func _ready() -> void:
	captured = []
	flying_away = []
	enter_state(GameState.SPIN_WEB)
	collection_goal_ui.set_target_collection(goal_flies)
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
	web_phase_song.play(GameData.get_spot_for_song("web_song"))
	print("web stage")
	web_tool.enable_web_system(true)
	scoreboard.show_scoreboard(false)
	
func start_critter_spawn_phase():
	GameData.set_song_save_spot("web_song", web_phase_song.get_playback_position())
	web_phase_song.stop()
	fly_phase_song.play(GameData.get_spot_for_song("fly_song"))
	print("spawn enemies")
	spawn_critters_btn.visible = false
	web_tool.enable_web_system(false)
	for spawner in spawners:
		spawner.enable_spawning(true)

func show_score_phase():
	print("show score")
	await get_tree().create_timer(2.0).timeout
	GameData.set_song_save_spot("fly_song", fly_phase_song.get_playback_position())
	fly_phase_song.stop()
	web_phase_song.play(GameData.get_spot_for_song("web_song"))
	scoreboard.show_scoreboard(true)
	scoreboard.set_score(captured.size(), flying_away.size(), captured.size() >= goal_flies, captured.size() == total_flies)
	
func go_to_next_level():
	GameData.set_song_save_spot("web_song", web_phase_song.get_playback_position())
	web_phase_song.stop()
	get_tree().change_scene_to_file(GameData.next_level())

func update_fly_data(f: Node, type: String):
	match type:
		"caught":
			if not captured.has(f):
				captured.append(f)
		"fleeing":
			if captured.has(f):
				captured.erase(f)
			if not flying_away.has(f):
				flying_away.append(f)
	
func set_total_flies(t: int):
	if total_flies == -1:
		total_flies = t
	else:
		total_flies += t
