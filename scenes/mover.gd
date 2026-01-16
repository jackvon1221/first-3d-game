extends Node3D

@export var distance := 3.0
@export var speed := 2.0

var start_pos: Vector3

func _ready():
	start_pos = position

func _process(delta):
	position.x = start_pos.x + sin(Time.get_ticks_msec() / 1000.0 * speed) * distance
