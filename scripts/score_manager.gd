extends CanvasLayer

@onready var score_label: Label = $ScoreBoard/Column/ScoreLabel
@onready var missed_label: Label = $ScoreBoard/Column/MissedLabel
@onready var scoreboard: Control = $ScoreBoard
@onready var next_level_btn: Button = $ScoreBoard/Column/Row/NextLvlBtn
@onready var retry_level_btn: Button = $ScoreBoard/Column/Row/RetryBtn
@onready var perfect_label: Label = $ScoreBoard/Panel/PerfectLabel
@onready var click_audio = $"ClickSoundAudioStream"
@onready var game_controller = $"GameController"
@onready var pass_fail_label: Label = $ScoreBoard/Panel/PassFailLabel

var score: int = 0
var missed: int = 0
signal restart_level
signal next_level

func _ready() -> void:
	update_score_display(false, false)
	show_scoreboard(false)
	perfect_label.visible = false
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

func set_score(s: int, m: int, passed: bool, perfect: bool) -> void:
	score = s
	missed = m
	update_score_display(passed, perfect)

func update_score_display(passed: bool, perfect: bool) -> void:
	if passed:
		pass_fail_label.text = "Passed"
		next_level_btn.disabled = false
	else:
		pass_fail_label.text = "Failed"
		next_level_btn.disabled = true
	if perfect:
		perfect_score()
	score_label.text = "Captured: %d" % score
	missed_label.text = "Escaped: %d" % missed
	
func show_scoreboard(should_show: bool):
	if scoreboard:
		scoreboard.visible = should_show

func perfect_score():
	perfect_label.visible = true
