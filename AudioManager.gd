extends Node

var click_sfx: AudioStreamPlayer
var music_player: AudioStreamPlayer
var toggle = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	click_sfx = AudioStreamPlayer.new()
	add_child(click_sfx)
	

func play_click():
	click_sfx.stream = preload("res://digital-click2.mp3")
	click_sfx.play()
	
func play_pause():
	click_sfx.stream = preload("res://digital-click-pause.mp3")
	click_sfx.play()
	
func play_menu_music():
	if music_player.stream == preload("res://piano_main_menu.mp3") and music_player.playing:
		return

	music_player.stream = preload("res://piano_main_menu.mp3")
	music_player.play()
	music_player.volume_db = -4

func stop_music():
	music_player.stop()
	
func toggle_music():
	if toggle:
		music_player.volume_db = -80
		toggle = !toggle
	else:
		music_player.volume_db = -4
		toggle = !toggle
