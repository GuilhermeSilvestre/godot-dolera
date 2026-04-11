extends Control

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		AudioManager.play_click()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
