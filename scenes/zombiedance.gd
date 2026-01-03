extends CharacterBody3D

signal died

var health = 3
var speed = 3.0                # horizontal speed
var jump_velocity = 8.0        # upward jump strength
var touching_player := false
var gravity = 20.0             # vertical gravity

# Death physics variables
var is_dead = false
var death_velocity = Vector3.ZERO
var death_rotation_speed = 0.0

@onready var zombiemodel = $zombiemodel
@onready var timer: Timer = $Timer
@onready var hurtsound: AudioStreamPlayer3D = $hurtsound
@onready var k_osound: AudioStreamPlayer3D = $KOsound
@onready var floor_ray: RayCast3D = $FloorRay
@onready var player = get_node("/root/Game/Player")
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	# Store original collision layers/masks
	pass

func _physics_process(delta):
	if is_dead:
		# Handle death physics
		_death_physics(delta)
		return
	
	if health <= 0:
		return

	# direction toward player
	var direction = global_position.direction_to(player.global_position)
	direction.y = 0
	direction = direction.normalized()

	# horizontal movement
	if not touching_player:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	# vertical movement / gravity
	if is_on_floor():
		if floor_ray.is_colliding() == false:
			# No floor detected below → jump
			velocity.y = jump_velocity
		else:
			# standing on floor, stop downward velocity
			if velocity.y < 0:
				velocity.y = 0
	else:
		# in air → apply gravity
		velocity.y -= gravity * delta

	# move the character
	move_and_slide()

	# rotate model to face player
	zombiemodel.rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP) + PI

func _death_physics(delta):
	# Apply gravity to death velocity
	death_velocity.y -= gravity * delta
	
	# Optional: Add some drag/air resistance
	death_velocity *= 0.99
	
	# Set velocity and move
	velocity = death_velocity
	move_and_slide()
	
	# Add some rotation for visual effect
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
	
	# Death knockback: push away from player + upward
	var direction = -global_position.direction_to(player.global_position)
	direction.y = 0
	direction = direction.normalized()
	var random_upward = Vector3.UP * randf_range(3.0, 6.0)
	
	# Set death velocity (this includes both knockback and upward force)
	death_velocity = direction * 12.0 + random_upward
	
	# Add random rotation speed for visual effect
	death_rotation_speed = randf_range(-8.0, 8.0)
	
	# Disable collisions with walls/floors to prevent sticking
	# You can adjust these based on your layer setup
	collision_mask = 0
	collision_layer = 0
	
	# Or if you want to keep some collisions but not with walls:
	# set_collision_mask_value(1, false)  # Disable layer 1 (world)
	# set_collision_mask_value(2, false)  # Disable layer 2 (other enemies)
	
	k_osound.play()
	timer.start()
	died.emit()
	
func _on_body_entered(body):
	if body == player:
		touching_player = true

func _on_body_exited(body):
	if body == player:
		touching_player = false

func _on_timer_timeout() -> void:
	queue_free()
