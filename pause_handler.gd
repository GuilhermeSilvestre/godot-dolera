extends Node

@onready var paused = $"../CanvasLayer/Paused"

func _input(event):
	if event.is_action_pressed("pause"):
		paused.visible = not paused.visible
		get_tree().paused = not get_tree().paused
		print("Paused =", get_tree().paused)
