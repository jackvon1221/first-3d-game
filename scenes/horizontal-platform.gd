extends AnimatableBody3D

@export var speed := 5.0
@export var distance := 7.0

var start_pos: Vector3
var direction := 1.0

func _ready():
	start_pos = global_position

func _physics_process(delta):
	var offset = global_position.z - start_pos.z

	if abs(offset) >= distance:
		direction *= -1.0

	global_position.z += direction * speed * delta
