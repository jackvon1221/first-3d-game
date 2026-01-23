extends Control

var starting := false

func _ready():
	modulate.a = 1


func _input(event):
	if event.is_pressed():
		starting = true
	if event.is_action_pressed("pause"):
		get_tree().quit()
func _process(delta):
	if starting:
		modulate.a -= delta * 2.5
		if modulate.a <= 0:
			get_tree().change_scene_to_file("res://scenes/Level-01.tscn")
