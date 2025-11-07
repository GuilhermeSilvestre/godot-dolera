extends Node

var enemy_kills: int = 0

func _ready() -> void:
	enemy_kills = 0

func add_kill():
	enemy_kills += 1
	print("🩸 Total kills:", enemy_kills)
