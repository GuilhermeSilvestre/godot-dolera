extends Control

@onready var score_label = $ScoreLabel

func _ready():
	pass

func _on_mouse_pressed() -> void:
	GameState.control_mode = "mouse"
	print("Moving Character with Mouse")
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_wasd_pressed() -> void:
	print("Moving Character with WASD")
	GameState.control_mode = "wasd"
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://MainMenu.tscn")
