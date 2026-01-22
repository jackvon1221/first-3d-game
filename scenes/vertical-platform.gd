extends AnimatableBody3D

@export var speed := 3.0
@export var distance := 4.5

var start_pos: Vector3
var direction := 1.0

func _ready():
	start_pos = global_position

func _physics_process(delta):
	var offset = global_position.y - start_pos.y

	if abs(offset) >= distance:
		direction *= -1.0

	global_position.y += direction * speed * delta
