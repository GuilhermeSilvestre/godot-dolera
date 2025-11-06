extends WorldEnvironment

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
	total_time += delta

	# ajusta a velocidade de spawn conforme o tempo de jogo
	if total_time < 30:
		spawn_timer.wait_time = 4.0
		#print("First wave - Light Sunday")
	elif total_time < 60:
		spawn_timer.wait_time = 2.0
		#print("Second wave - Begginers Guide")
	elif total_time < 120:
		spawn_timer.wait_time = 1.0
		#print("Third wave - Ragnaroke")
	elif total_time < 180:
		spawn_timer.wait_time = 0.5
		#print("Fourth wave - Apocalypse")
	else:
		spawn_timer.wait_time = 0.2
		#print("Last wave - Eclipse")

	# garante que o timer atualize o novo tempo se mudar
	if spawn_timer.time_left > spawn_timer.wait_time:
		spawn_timer.start(spawn_timer.wait_time)

	if Input.is_action_just_pressed("mute"):
		toggle_mute()

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
