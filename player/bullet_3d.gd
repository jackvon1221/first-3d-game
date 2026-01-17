extends Area3D

const SPEED = 20.0
const RANGE = 40.0

var travelled_distance = 0.0


func _physics_process(delta):
	position += -transform.basis.z * SPEED * delta
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body):
	print("Bullet hit:", body.name)

	if body.has_method("take_damage"):
		body.take_damage()

		# NEW: rumble on confirmed hit
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("rumble_hit"):
			player.rumble_hit()

	queue_free()
