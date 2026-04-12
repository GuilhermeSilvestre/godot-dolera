extends Node

var enemy_kills: int = 0
var last_run_kills: int = 0
var highscore: int = 0

func _ready() -> void:
	enemy_kills = 0

func add_kill():
	enemy_kills += 1
	print("🩸 Total kills:", enemy_kills)

func end_run():
	last_run_kills = enemy_kills
	
	if enemy_kills > highscore:
		highscore = enemy_kills
	
	enemy_kills = 0
