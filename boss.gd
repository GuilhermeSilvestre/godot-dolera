extends CharacterBody3D

var life := 20
var is_dead := false
var is_taking_hit := false

@export var base_speed := 17.0
@export var speed_variation := 8.0

var speed := 0.0
var player

# 💥 DANO
var can_damage := true
var damage_cooldown := 1.0

# 🔥 STUCK
var last_position := Vector3.ZERO
var stuck_timer := 0.0

var STUCK_TIME := 0.8
var MIN_MOVEMENT := 0.02

# 🚀 DASH ANTI-STUCK
var is_unstucking := false
var UNSTUCK_SPEED := 38.0
var UNSTUCK_DURATION := 0.8

# 🎯 REFERÊNCIA VISUAL (IMPORTANTE)
@onready var mesh = $warlock1 # 👈 MUDA SE O NOME FOR DIFERENTE

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	last_position = global_position
	randomize()

func _physics_process(delta):
	if player == null or is_dead:
		return

	# 🚀 SE ESTÁ EM DASH
	if is_unstucking:
		move_and_slide()
		return

	# 🔥 velocidade variável
	speed = base_speed + sin(Time.get_ticks_msec() / 400.0) * speed_variation

	# 🧭 direção até o player
	var direction = player.global_position - global_position
	direction.y = 0
	direction = direction.normalized()

	# 👁️ rotação
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, delta * 8.0)

	# 🚶 movimento
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

	# 🔥 DETECTOR DE STUCK
	var moved = global_position.distance_to(last_position)

	if moved < MIN_MOVEMENT:
		stuck_timer += delta
	else:
		stuck_timer = 0.0

	last_position = global_position

	if stuck_timer >= STUCK_TIME and not is_unstucking:
		print("⚠️ STUCK → DASH")
		unstuck_dash()
		stuck_timer = 0.0

	# 💥 dano
	check_damage()


func check_damage():
	if not can_damage or is_dead:
		return

	if global_position.distance_to(player.global_position) < 2.6:
		can_damage = false

		if player.has_method("take_damage"):
			player.take_damage(2)

		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true


func unstuck_dash():
	if player == null:
		return

	is_unstucking = true

	var dir = (player.global_position - global_position).normalized()
	dir.y = 0

	var random_offset = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	).normalized()

	dir = (dir + random_offset).normalized()

	speed = UNSTUCK_SPEED
	velocity = dir * speed

	await get_tree().create_timer(UNSTUCK_DURATION).timeout

	speed = base_speed
	is_unstucking = false


func die():
	if is_dead:
		return
	
	if is_taking_hit:
		return
	
	is_taking_hit = true

	life -= 1
	print("👹 Boss HP:", life)

	# 🔊 SOM DE DANO (só se não for o último hit)
	if life > 0:
		var hit_sfx = AudioStreamPlayer.new()
		get_tree().root.add_child(hit_sfx)

		hit_sfx.stream = load("res://boss_demage.mp3")
		hit_sfx.volume_db = 5
		hit_sfx.play()

		hit_sfx.finished.connect(hit_sfx.queue_free)

	# 🔥 VISUAL
	if mesh:
		mesh.modulate = Color(1, 0.3, 0.3)

	await get_tree().create_timer(0.1).timeout

	if mesh:
		mesh.modulate = Color(1, 1, 1)

	# 💀 MORTE (COM DELAY)
	if life <= 0:
		is_dead = true
		print("💀 BOSS MORREU")

		# ❄️ congela o boss
		set_physics_process(false)
		set_process(false)
		velocity = Vector3.ZERO

		# ⏳ espera 1 segundo (drama)
		await get_tree().create_timer(1.0).timeout

		# 🔥 chama world (fade bonito)
		var world = get_tree().get_first_node_in_group("world")
		if world:
			world._on_boss_died()

		# 🔊 SOM DE MORTE
		var death_sfx = AudioStreamPlayer.new()
		get_tree().root.add_child(death_sfx)

		death_sfx.stream = load("res://boss_die.mp3")
		death_sfx.volume_db = 5
		death_sfx.play()

		death_sfx.finished.connect(death_sfx.queue_free)

		queue_free()
		return

	is_taking_hit = false
