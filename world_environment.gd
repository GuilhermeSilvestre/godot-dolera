extends WorldEnvironment

var music_player: AudioStreamPlayer
var current_track := -1
var tracks = [
	load("res://Sounds/music1.mp3"),
	load("res://Sounds/music2.mp3"),
	load("res://Sounds/scary-ambience.mp3")
]

var is_muted := false  # controla se está mutado

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	_play_next_track()

func _process(_delta):
	if Input.is_action_just_pressed("mute"):  # cria esta action no Input Map para a tecla M
		toggle_mute()

func _play_next_track():
	current_track = (current_track + 1) % tracks.size()
	music_player.stream = tracks[current_track]

	# Define volumes diferentes conforme a faixa
	if current_track == 0:
		music_player.volume_db = 0      # normal
	elif current_track == 1:
		music_player.volume_db = 6      # um pouco mais alto
	elif current_track == 2:
		music_player.volume_db = -8     # um pouco mais baixo

	# Se estiver mutado, força volume 0
	if is_muted:
		music_player.volume_db = -80  # volume mínimo efetivo

	music_player.play()

func _on_music_finished():
	_play_next_track()

# Função para alternar mute
func toggle_mute():
	is_muted = !is_muted
	if is_muted:
		music_player.volume_db = -80
	else:
		# Restaura volume da faixa atual
		if current_track == 0:
			music_player.volume_db = 0
		elif current_track == 1:
			music_player.volume_db = 6
		elif current_track == 2:
			music_player.volume_db = -8
