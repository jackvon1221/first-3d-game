extends CharacterBody3D

@export var speed := 5.5
@export var gravity := 20.0
@export var jump_velocity := 10.0
@export var mouse_sensitivity := 0.35
@export var pitch_sensitivity := 0.15
@export var knockback_strength := 10.0  # How strong the knockback is
@export var knockback_cooldown := 0.5    # Seconds between knockbacks

@onready var jumpsound: AudioStreamPlayer = %jumpsound
@onready var shoot_sound: AudioStreamPlayer = %AudioStreamPlayer
@onready var shoot_timer: Timer = %Timer
@onready var camera: Camera3D = %Camera3D
@onready var muzzle: Marker3D = %Marker3D
@onready var pushed: AudioStreamPlayer = %pushed

var camera_pitch := 0.0
var can_be_knocked_back := true
var knockback_timer := Timer.new()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup knockback cooldown timer
	add_child(knockback_timer)
	knockback_timer.one_shot = true
	knockback_timer.timeout.connect(_on_knockback_cooldown_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera_pitch -= event.relative.y * pitch_sensitivity
		camera_pitch = clamp(camera_pitch, -40.0, 40.0)
		camera.rotation_degrees.x = camera_pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	# Player movement
	var input_dir = Input.get_vector("move_left","move_right","move_forward","move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Only apply movement if we're not currently in knockback
	if can_be_knocked_back:  # Normal movement
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jumpsound.play()
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0

	# Move player
	move_and_slide()

	# Check for collisions with zombies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var col = collision.get_collider()
		
		# Check if it's a zombie that can knock us back
		if col and col is RigidBody3D and col.has_node("zombiecollision") and can_be_knocked_back:
			print("*** ZOMBIE HIT DETECTED! Applying knockback ***")
			print("Zombie position: ", col.global_position)
			print("Player position: ", global_position)
			
			# PLAY HIT SOUND
			if pushed:
				pushed.play()
			
			# Calculate direction away from zombie
			var knockback_direction = (global_position - col.global_position).normalized()
			
			# Apply knockback - horizontal push
			velocity.x = knockback_direction.x * knockback_strength
			velocity.z = knockback_direction.z * knockback_strength
			
			# Add small upward bounce
			velocity.y = 8.0
			
			# Prevent further knockback for a short time
			can_be_knocked_back = false
			knockback_timer.start(knockback_cooldown)
			
			# Only process one zombie collision per frame
			break

	# Shooting
	if Input.is_action_just_pressed("shoot") and shoot_timer.is_stopped():
		shoot_bullet()

func _on_knockback_cooldown_timeout():
	can_be_knocked_back = true

func jump():
	velocity.y = jump_velocity
	jumpsound.play()

func shoot_bullet():
	const BULLET_3D = preload("uid://tyxadroe7tlv")
	var bullet = BULLET_3D.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	var dir = -camera.global_transform.basis.z
	bullet.look_at(bullet.global_position + dir, Vector3.UP)
	shoot_timer.start()
	shoot_sound.play()

# Optional: You can call this function from the zombie script if you prefer
func knockback_from(enemy_position: Vector3, strength: float = 100.0):
	if not can_be_knocked_back:
		return
	
	# PLAY HIT SOUND
	if pushed:
		pushed.play()
	
	var push_direction = (global_position - enemy_position).normalized()
	velocity.x = push_direction.x * strength
	velocity.z = push_direction.z * strength
	velocity.y = 8.0  # Small upward bounce
	
	can_be_knocked_back = false
	knockback_timer.start(knockback_cooldown)
