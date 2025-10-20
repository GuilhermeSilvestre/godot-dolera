extends Area3D

const SPEED = 8.0
const MAX_DISTANCE = 200.0

var direction : Vector3
var distance_traveled : float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	var movement = direction * SPEED * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= MAX_DISTANCE:
		queue_free()

func _on_body_entered(_body):
	queue_free()

func set_direction(dir: Vector3):
	direction = dir.normalized()
