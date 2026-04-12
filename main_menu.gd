extends Control

@onready var score_label = $ScoreLabel

func _ready():
	AudioManager.play_menu_music()
	score_label.text = "Last run: " + str(GameState.last_run_kills) + "\nHighscore: " + str(GameState.highscore)
	
func _on_play_pressed():
	AudioManager.stop_music()
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://level.tscn")

func _on_how_to_play_pressed():
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://howtoplay.tscn")
	
func _on_credits_pressed():
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://credits.tscn")

func _on_sound_pressed() -> void:
	AudioManager.toggle_music()
