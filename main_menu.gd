extends Control

@onready var score_label = $ScoreLabel

func _ready():
	AudioManager.play_menu_music()
	score_label.text = "Last run: %d\nHighscore: %d" % [
		GameState.last_run_kills,
		GameState.highscore
	]
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
	
func _on_mouse_mode_pressed():
	GameState.control_mode = "mouse"

#func _on_wasd_mode_pressed():
	#GameState.control_mode = "wasd"
	
func _on_controls_pressed():
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://controls.tscn")
