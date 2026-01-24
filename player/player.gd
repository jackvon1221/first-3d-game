extends CharacterBody3D

@export var speed := 5.5
@export var gravity := 20.0
@export var jump_velocity := 10.0
@export var mouse_sensitivity := 0.35
@export var pitch_sensitivity := 0.15
@export var knockback_strength := 10.0  # How strong the knockback is
@export var knockback_cooldown := 0.5    # Seconds between knockbacks
@export var stick_look_sensitivity := 2.5
@export var stick_deadzone := 0.15
@onready var jumpsound: AudioStreamPlayer = %jumpsound
@onready var shoot_sound: AudioStreamPlayer = %AudioStreamPlayer
@onready var shoot_timer: Timer = %Timer
@onready var camera: Camera3D = %Camera3D
@onready var muzzle: Marker3D = %Marker3D
@onready var pushed: AudioStreamPlayer = %pushed
@onready var anim_player = $CollisionShape3D/SQUIBBOMOVING/AnimationPlayer
@onready var anim_tree = $CollisionShape3D/SQUIBBOMOVING/AnimationTree
@onready var melee_sound: AudioStreamPlayer3D = $MeleeSound
@onready var camera_base_pos: Vector3 = camera.position
@onready var sprint_sound: AudioStreamPlayer = $SprintSound


var camera_pitch := 0.0
var can_be_knocked_back := true
var knockback_timer := Timer.new()
var cam_shake_time := 0.0
var cam_shake_strength := 0.03


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_child(knockback_timer)
	knockback_timer.one_shot = true
	knockback_timer.timeout.connect(_on_knockback_cooldown_timeout)
func rumble_hit():
	if Input.get_connected_joypads().size() == 0:
		return

	var device := Input.get_connected_joypads()[0]
	Input.start_joy_vibration(device, 0.3, 0.8, 0.15)

func melee_attack():
	

	var space = get_world_3d().direct_space_state
	var from = global_transform.origin + Vector3.UP * 1.0
	var to = from + (-global_transform.basis.z * 2.5)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result = space.intersect_ray(query)

	if result:
		var hit = result.collider

		if hit.has_method("take_damage"):
			hit.take_damage()
			rumble_hit()
	else:
		print("HIT: nothing")

func _input(event):
	if event.is_action_pressed("hit") and is_on_floor():
		melee_attack()
		melee_sound.play()
		anim_tree.set(
			"parameters/oneshot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

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
	var look_input := Input.get_vector(
		"look_left",
		"look_right",
		"look_up",
		"look_down"
	)	
	if look_input.length() > stick_deadzone:
		rotation.y -= look_input.x * stick_look_sensitivity * delta * 1.0
	
		camera_pitch -= look_input.y * stick_look_sensitivity * delta * 1.0
		camera_pitch = clamp(camera_pitch, -40.0, 40.0)
		camera.rotation.x = camera_pitch
	
	# --- SPRINT STATE ---
	var is_sprinting := Input.is_action_pressed("sprint") and is_on_floor()
	if is_sprinting and anim_player.current_animation != "sprint_001":
		anim_player.play("sprint_001")
	
	
# --- MOVEMENT SPEED (THIS IS THE IMPORTANT PART) ---
	if can_be_knocked_back:
		var s = speed * (1.8 if is_sprinting else 1.0)
		velocity.x = direction.x * s
		velocity.z = direction.z * s

# --- SPRINT CAMERA + SOUND ---
	if is_sprinting:
	# Subtle camera shake
		cam_shake_time += delta * 12.0
		var offset = Vector3(
			sin(cam_shake_time) * (cam_shake_strength * 0.8),
			cos(cam_shake_time * 2.0) * (cam_shake_strength * 0.8),
			0.0
		)
		camera.position = camera_base_pos + offset

	# Sprint sound
		if not sprint_sound.playing:
			sprint_sound.play()
	else:
	# Reset camera
		cam_shake_time = 0.0
		camera.position = camera.position.lerp(camera_base_pos, 8.0 * delta)

	# Stop sprint sound
		if sprint_sound.playing:
			sprint_sound.stop()



	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jumpsound.play()
		anim_tree.set(
			"parameters/OneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0

	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0

	# Move player
	move_and_slide()

	# Check for collisions with zombies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var col = collision.get_collider()
		
		# Check if it's a zombie that can knock us back
		if col and col is CharacterBody3D and col.has_node("zombiecollision") and can_be_knocked_back:
			print("*** ZOMBIE HIT DETECTED! Applying knockback ***")
			print("Zombie position: ", col.global_position)
			print("Player position: ", global_position)
			
			# PLAY HIT SOUND
			if pushed:
				pushed.play()
			
			# Calculate direction away from zombie
			var knockback_direction = global_position - col.global_position
			knockback_direction.y = 0
			knockback_direction = knockback_direction.normalized()
			
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
