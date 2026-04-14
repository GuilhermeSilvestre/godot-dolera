extends WorldEnvironment

@onready var help_ui = $"../CanvasLayer/Help"
@onready var level_text = $"../CanvasLayer/Level"
@onready var enemykilled = $"../CanvasLayer/enemykilled"
@onready var timescore = $"../CanvasLayer/TimeScore"
@onready var upgrade_label = $"../CanvasLayer/upgrade"
var sfx_player: AudioStreamPlayer
@onready var warlock_player = $"../Warlock"

var fade_done := false
var current_level_stage := 1
var last_upgrade_kill := 0
var BossScene = preload("res://boss.tscn")
var credits_bonus_applied := false

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

var stopped_spawning := false

func _ready():
	add_to_group("world")
	warlock_player = get_node("../Warlock")

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	_play_next_track()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
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
	
	@warning_ignore("integer_division")
	var minutes = int(total_time) / 60
	var seconds = int(total_time) % 60
	var min_str = "0" + str(minutes) if minutes < 10 else str(minutes)
	var sec_str = "0" + str(seconds) if seconds < 10 else str(seconds)
	timescore.text = min_str + ":" + sec_str
	

	# Se aguentar 90 segundos e matar 60 bonecos - Chega no Boss
	if not stopped_spawning and total_time >= 90 and GameState.enemy_kills >= 60:
		stopped_spawning = true
		spawn_timer.stop()
		print("SPAWN PARADO")
		music_player.stop()
		await get_tree().create_timer(0.2).timeout
		var enemies = []
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				enemies.append(e)

		for enemy in enemies:
			if is_instance_valid(enemy):
				if enemy.has_method("set_physics_process"):
					enemy.set_physics_process(false)
					enemy.set_collision_layer(0)
					enemy.set_collision_mask(0)

		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.has_method("die"):
				enemy.die(false, false)
				await get_tree().create_timer(0.05).timeout

		level_text.text = "You have the chance to see him..."
		_do_level_fade()
		
		await get_tree().create_timer(1.0).timeout
		var boss = BossScene.instantiate()
		add_child(boss)

		boss.global_position = Vector3(0, 1.5, 2)
	
	# A cada 5 bonecos mortos o Player vai ganhar um Buff
	if GameState.enemy_kills != last_upgrade_kill:
		last_upgrade_kill = GameState.enemy_kills
		match GameState.enemy_kills:
			5:
				warlock_player.BASE_SPEED += 3
				warlock_player.SPEED = warlock_player.BASE_SPEED
			10:
				warlock_player.FAST_MOVE_COOLDOWN = max(0.5, warlock_player.FAST_MOVE_COOLDOWN - 2)
				warlock_player.fireball_speed = 11
				warlock_player.fireball_cast_delay = 1.25
			15:
				warlock_player.TELEPORT_COOLDOWN = max(0.5, warlock_player.TELEPORT_COOLDOWN - 2)
			20:
				warlock_player.TELEPORT_DELAY = max(0.1, 0.5)
				warlock_player.fireball_speed = 14
				warlock_player.fireball_cast_delay = 1.0
			25:
				warlock_player.BASE_SPEED += 4
				warlock_player.SPEED = warlock_player.BASE_SPEED
				warlock_player.fireball_cast_delay = 0.9
			30:
				warlock_player.TELEPORT_COOLDOWN = max(0.5, warlock_player.TELEPORT_COOLDOWN - 1)
			35:
				warlock_player.FAST_MOVE_SPEED = 27
			40:
				warlock_player.life = 8
				warlock_player.update_hearts()
			45:
				warlock_player.TELEPORT_MAX_DISTANCE = 20
			50:
				warlock_player.fireball_speed = 30
				warlock_player.fireball_cast_delay = 0.5
			60:
				warlock_player.BASE_SPEED += 3
				warlock_player.fireball_speed = 35
				warlock_player.fireball_cast_delay = 0.4
				warlock_player.TELEPORT_COOLDOWN = max(0.5, warlock_player.TELEPORT_COOLDOWN - 1)
				warlock_player.FAST_MOVE_COOLDOWN = max(0.5, warlock_player.FAST_MOVE_COOLDOWN - 1)
			_:
				return
		upgrade_label.text = "Upgraded Powers"
		_do_upgrade_fade()
		sfx_player.stream = preload("res://Sounds/powerup.mp3")
		sfx_player.volume_db = 2
		sfx_player.play()

	# ajusta a velocidade de spawn conforme o tempo de jogo
	if total_time < 10:
		spawn_timer.wait_time = 4.0
		#print("First wave - Beautiful Sunday Morning")
	elif total_time < 30:
		spawn_timer.wait_time = 2.0
		#print("Second wave - Beginner's Guide")
	elif total_time < 50:
		spawn_timer.wait_time = 1.0
		#print("Third wave - Ragnarok")
	elif total_time < 70:
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
		
	if Input.is_action_just_pressed("mainmenu"):
		GameState.end_run()
		AudioManager.play_click()
		AudioManager.play_menu_music()
		get_tree().change_scene_to_file("res://MainMenu.tscn")
# 
	if total_time >= 70 and current_level_stage < 4:
		current_level_stage = 4
		level_text.text = "Final Eclipse Level"
		_do_level_fade()

	elif total_time >= 50 and current_level_stage < 3:
		current_level_stage = 3
		level_text.text = "Apocalypse Level"
		_do_level_fade()

	elif total_time >= 30 and current_level_stage < 2:
		current_level_stage = 2
		level_text.text = "Ragnarok Level"
		_do_level_fade()

	elif total_time >= 1 and total_time <= 2 and current_level_stage < 2:
		current_level_stage = 1
		level_text.text = "Calm Before the Storm"
		_do_level_fade()
		
	if GameState.credits_opened >= 10:
		warlock_player.fireball_speed = max(warlock_player.fireball_speed, 40)
		warlock_player.fireball_cast_delay = min(warlock_player.fireball_cast_delay, 0.2)
		warlock_player.SPEED = max(warlock_player.SPEED, 13)

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
		AudioServer.set_bus_volume_db(0, -80)
	else:
		AudioServer.set_bus_volume_db(0, 0)
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

func _do_upgrade_fade():
	upgrade_label.visible = true
	upgrade_label.modulate = Color(0.955, 0.225, 0.088, 1.0)  # vermelho
	var tween = create_tween()
	tween.parallel().tween_property(upgrade_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(upgrade_label, "modulate", Color(0.975, 0.592, 0.056, 1.0), 0.3)
	tween.tween_interval(0.6)
	tween.tween_property(upgrade_label, "modulate:a", 0.0, 0.3)
	
func _update_enemy_kills():
	enemykilled.text = " Enemies Killed: %d" % GameState.enemy_kills
	
func _on_boss_died():
	level_text.text = "You defeated the Square Head!"
	await get_tree().create_timer(2.0).timeout
	_do_boss_fade()
	await get_tree().create_timer(3.0).timeout
	GameState.end_run()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _do_boss_fade():
	level_text.visible = true
	
	# 🔥 começa vermelho forte
	level_text.modulate = Color(0.9, 0.1, 0.1, 1.0)

	var tween = create_tween()

	# 🔥 fade in + muda pra dourado
	tween.parallel().tween_property(level_text, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(level_text, "modulate", Color(1.0, 0.75, 0.2, 1.0), 1.0)

	# ⏳ segura mais tempo (dramático)
	tween.tween_interval(2.0)

	# 🌫️ fade out lento
	tween.tween_property(level_text, "modulate:a", 0.0, 1.5)

	# 🔊 SOM DE VITÓRIA (fora da cena pra não morrer)
	var sfx = AudioStreamPlayer.new()
	get_tree().root.add_child(sfx)

	sfx.stream = load("res://victory.mp3")
	sfx.volume_db = 5
	sfx.play()

	sfx.finished.connect(sfx.queue_free)
