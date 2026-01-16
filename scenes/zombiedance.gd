extends CharacterBody3D

signal died

var health = 1
var speed = 3.0                
var jump_velocity = 8.0        
var touching_player := false
var gravity = 20.0             


var is_dead = false
var death_velocity = Vector3.ZERO
var death_rotation_speed = 0.0

@onready var zombiemodel = $zombiemodel
@onready var timer: Timer = $Timer
@onready var hurtsound: AudioStreamPlayer3D = $hurtsound
@onready var k_osound: AudioStreamPlayer3D = $KOsound
@onready var floor_ray: RayCast3D = $FloorRay
@onready var player = get_tree().get_first_node_in_group("player")
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	pass

func _physics_process(delta):
	if not is_instance_valid(player):
		return
	if is_dead:
		_death_physics(delta)
		return
	if health <= 0:
		return
	var direction = global_position.direction_to(player.global_position)
	direction.y = 0
	direction = direction.normalized()

	if not touching_player:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	if is_on_floor():
		if floor_ray.is_colliding() == false:
			velocity.y = jump_velocity
		else:
			if velocity.y < 0:
				velocity.y = 0
	else:
		velocity.y -= gravity * delta
	move_and_slide()

	zombiemodel.rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP) + PI

func _death_physics(delta):
	death_velocity.y -= gravity * delta
	death_velocity *= 0.99
	velocity = death_velocity
	move_and_slide()
	zombiemodel.rotation.y += death_rotation_speed * delta
	zombiemodel.rotation.x += death_rotation_speed * 0.5 * delta

func take_damage():
	if health == 0:
		return

	zombiemodel.hurt()
	health -= 1
	hurtsound.play()

	if health == 0:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	died.emit()
	var direction = -global_position.direction_to(player.global_position)
	direction.y = 0
	direction = direction.normalized()
	var random_upward = Vector3.UP * randf_range(3.0, 6.0)

	death_velocity = direction * 12.0 + random_upward

	death_rotation_speed = randf_range(-8.0, 8.0)

	collision_mask = 0
	collision_layer = 0
	
	k_osound.play()
	timer.start()
	
func _on_body_entered(body):
	if body == player:
		touching_player = true

func _on_body_exited(body):
	if body == player:
		touching_player = false

func _on_timer_timeout() -> void:
	queue_free()
	
