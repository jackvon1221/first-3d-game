extends RigidBody3D

var health = 3
var speed = randf_range(2.0, 4.0)
var touching_player := false

@onready var zombiemodel = %zombiemodel
@onready var timer: Timer = %Timer
@onready var hurtsound: AudioStreamPlayer3D = %hurtsound
@onready var k_osound: AudioStreamPlayer3D = %KOsound

@onready var player = get_node("/root/Game/Player")

func _ready():
	lock_rotation = true
	gravity_scale = 1.0
	linear_damp = 5.0

func _physics_process(delta):
	if health <= 0:
		return

	var direction = global_position.direction_to(player.global_position)
	direction.y = 0.0
	direction = direction.normalized()

	if not touching_player:
		var vel = linear_velocity  # copy current velocity
		vel.x = direction.x * speed
		vel.z = direction.z * speed
		if health > 0:
			vel.y = 0.0
		linear_velocity = vel
		
	zombiemodel.rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP) + PI

func take_damage():
	if health == 0:
		return

	zombiemodel.hurt()
	health -= 1
	hurtsound.play()

	if health == 0:
		set_physics_process(false)

		# Let physics take over for death
		lock_rotation = false
		linear_damp = 0.0
		angular_damp = 0.0
		gravity_scale = 1.0

		var direction = -global_position.direction_to(player.global_position)
		var random_upward_force = Vector3.UP * randf_range(3.0, 6.0)

		apply_central_impulse(direction * 12.0 + random_upward_force)

		timer.start()
		k_osound.play()

func _on_body_entered(body):
	if body == player:
		touching_player = true

func _on_body_exited(body):
	if body == player:
		touching_player = false

func _on_timer_timeout() -> void:
	queue_free()
