extends CharacterBody3D

@export var speed := 5.5
@export var gravity := 20.0
@export var jump_velocity := 10.0
@export var mouse_sensitivity := 0.35
@export var pitch_sensitivity := 0.15
@onready var jumpsound: AudioStreamPlayer = %jumpsound

var camera_pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Yaw (player)
		rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Pitch (camera only)
		camera_pitch -= event.relative.y * pitch_sensitivity
		camera_pitch = clamp(camera_pitch, -40.0, 40.0)

		%Camera3D.rotation_degrees.x = camera_pitch

	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)
	var direction := (transform.basis * Vector3(
		input_dir.x,
		0.0,
		input_dir.y
	)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
		%jumpsound.play()
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0
	

	move_and_slide()

	if Input.is_action_just_pressed("shoot") and %Timer.is_stopped():
		shoot_bullet()

func jump():
	velocity.y = jump_velocity
	jumpsound.play()

func shoot_bullet():
	const BULLET_3D = preload("uid://tyxadroe7tlv")
	var bullet = BULLET_3D.instantiate()

	get_tree().current_scene.add_child(bullet)

	# Spawn at character muzzle
	bullet.global_position = %Marker3D.global_position

	# Aim where the camera is looking
	var dir = -%Camera3D.global_transform.basis.z
	bullet.look_at(bullet.global_position + dir, Vector3.UP)

	%Timer.start()
	%AudioStreamPlayer.play()
func apply_knockback(from_position: Vector3, force: float = 10.0, upward: float = 5.0):
	var dir = (global_position - from_position).normalized()    
	velocity.x = dir.x * force
	velocity.z = dir.z * force
	velocity.y = upward
	set_physics_process(false)
	await get_tree().create_timer(0.2).timeout
	set_physics_process(true)
