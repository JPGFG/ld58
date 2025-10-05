extends CanvasLayer

@onready var score_label: Label = $ScoreBoard/Column/ScoreLabel
@onready var missed_label: Label = $ScoreBoard/Column/MissedLabel
@onready var scoreboard: Control = $ScoreBoard
@onready var next_level_btn: Button = $ScoreBoard/Column/Row/NextLvlBtn
@onready var retry_level_btn: Button = $ScoreBoard/Column/Row/RetryBtn
@onready var click_audio = $"ClickSoundAudioStream"
@onready var game_controller = $"GameController"

var score: int = 0
var missed: int = 0
signal restart_level
signal next_level

func _ready() -> void:
	update_score_display()
	show_scoreboard(false)
	next_level_btn.pressed.connect(func(): 
		click_audio.play()
		await get_tree().create_timer(1.0).timeout
		next_level.emit()
	)
	retry_level_btn.pressed.connect(func(): 
		click_audio.play()
		await get_tree().create_timer(1.0).timeout
		restart_level.emit()
	)

func set_score(s: int, m: int) -> void:
	score = s
	missed = m
	update_score_display()

func update_score_display() -> void:
	score_label.text = "Score: %d" % score
	missed_label.text = "Missed: %d" % missed
	
func show_scoreboard(should_show: bool):
	if scoreboard:
		scoreboard.visible = should_show
