extends CharacterBody3D

@export var speed := 5.5
@export var gravity := 20.0
@export var jump_velocity := 10.0
@export var mouse_sensitivity := 0.35
@export var pitch_sensitivity := 0.15

@onready var jumpsound: AudioStreamPlayer = %jumpsound
@onready var shoot_sound: AudioStreamPlayer = %AudioStreamPlayer
@onready var shoot_timer: Timer = %Timer
@onready var camera: Camera3D = %Camera3D
@onready var muzzle: Marker3D = %Marker3D

var camera_pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

	# Shooting
	if Input.is_action_just_pressed("shoot") and shoot_timer.is_stopped():
		shoot_bullet()

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
