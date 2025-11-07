extends WorldEnvironment

@onready var help_ui = $"../CanvasLayer/Help"
@onready var level_text = $"../CanvasLayer/Level"
@onready var enemykilled = $"../CanvasLayer/enemykilled"
@onready var timescore = $"../CanvasLayer/TimeScore"

var fade_done := false
var current_level_stage := 1

var music_player: AudioStreamPlayer
var current_track := -1
var tracks = [
	load("res://Sounds/music1.mp3"),
	load("res://Sounds/music2.mp3"),
	load("res://Sounds/scary-ambience.mp3")
]

var is_muted := false  # controla se está mutado
var enemy_scene = preload("res://enemy.tscn")

# controla o tempo total decorrido
var total_time := 0.0
var spawn_timer: Timer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	_play_next_track()
	
	# cria o Timer de spawn
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 3.0
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func _process(delta):
	_update_enemy_kills()
	total_time += delta
	
	var minutes = int(total_time) / 60
	var seconds = int(total_time) % 60
	var min_str = "0" + str(minutes) if minutes < 10 else str(minutes)
	var sec_str = "0" + str(seconds) if seconds < 10 else str(seconds)
	timescore.text = min_str + ":" + sec_str


	# ajusta a velocidade de spawn conforme o tempo de jogo
	if total_time < 30:
		spawn_timer.wait_time = 4.0
		#print("First wave - Beautiful Sunday Morning")
	elif total_time < 60:
		spawn_timer.wait_time = 2.0
		#print("Second wave - Beginner's Guide")
	elif total_time < 120:
		spawn_timer.wait_time = 1.0
		#print("Third wave - Ragnarok")
	elif total_time < 180:
		spawn_timer.wait_time = 0.5
		#print("Fourth wave - Apocalypse")
	else:
		spawn_timer.wait_time = 0.2
		#print("Last wave - Final Eclipse")

	# garante que o timer atualize o novo tempo se mudar
	if spawn_timer.time_left > spawn_timer.wait_time:
		spawn_timer.start(spawn_timer.wait_time)

	if Input.is_action_just_pressed("mute"):
		toggle_mute()
		
# 
	if total_time >= 180 and current_level_stage < 4:
		current_level_stage = 4
		level_text.text = "Final Eclipse"
		_do_level_fade()

	elif total_time >= 120 and current_level_stage < 3:
		current_level_stage = 3
		level_text.text = "Apocalypse Level"
		_do_level_fade()

	elif total_time >= 60 and current_level_stage < 2:
		current_level_stage = 2
		level_text.text = "Ragnarok Level"
		_do_level_fade()



func _play_next_track():
	current_track = (current_track + 1) % tracks.size()
	music_player.stream = tracks[current_track]

	if current_track == 0:
		music_player.volume_db = 0
	elif current_track == 1:
		music_player.volume_db = 6
	elif current_track == 2:
		music_player.volume_db = -8

	if is_muted:
		music_player.volume_db = -80

	music_player.play()

func _on_music_finished():
	_play_next_track()

func toggle_mute():
	is_muted = !is_muted
	if is_muted:
		music_player.volume_db = -80
	else:
		if current_track == 0:
			music_player.volume_db = 0
		elif current_track == 1:
			music_player.volume_db = 6
		elif current_track == 2:
			music_player.volume_db = -8

func _spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	var x = randf_range(-20, 20)
	var z = randf_range(-20, 20)
	enemy.global_position = Vector3(x, 0, z)

	print("Spawned enemy at:", enemy.global_position)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		help_ui.visible = not help_ui.visible
		
func _do_level_fade():
	level_text.visible = true
	var tween = create_tween()
	tween.tween_property(level_text, "modulate:a", 1.0, 1.5)  # fade in
	tween.tween_interval(1.0)
	tween.tween_property(level_text, "modulate:a", 0.0, 1.5)  # fade out
	
func _update_enemy_kills():
	enemykilled.text = " Enemies Killed: %d" % GameState.enemy_kills
