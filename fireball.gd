extends Area3D

const SPEED = 14.0
const MAX_DISTANCE = 200.0

var direction: Vector3
var distance_traveled: float = 0.0
var moving: bool = true
var exploded = false


func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	if moving:
		var movement = direction * SPEED * delta
		global_position += movement
		distance_traveled += movement.length()

		if distance_traveled >= MAX_DISTANCE:
			queue_free()

func _on_body_entered(_body):
	if exploded:
		return  # já explodiu, ignora novas colisões
	
	exploded = true
	
	moving = false
	
	var anim_player = get_node("fireballv2/AnimationPlayer")
	if anim_player:
		anim_player.play("Explosion")

		# cria e toca o som
		var explosion_sound = AudioStreamPlayer3D.new()
		explosion_sound.stream = load("res://Sounds/explosion.mp3")
		add_child(explosion_sound)
		explosion_sound.play()

		# espera ANIMAÇÃO terminar
		await anim_player.animation_finished

		# espera o SOM terminar
		await explosion_sound.finished

		queue_free()
	else:
		queue_free()

func set_direction(dir: Vector3):
	direction = dir.normalized()
