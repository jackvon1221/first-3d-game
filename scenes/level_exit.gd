extends Area3D

@onready var exit_sound = $ExitSound
var triggered := false

func _on_body_entered(body):
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		if exit_sound:
			exit_sound.play()
		# Give the sound time to play
		await get_tree().create_timer(0.9).timeout
		get_tree().change_scene_to_file("res://scenes/Level-02.tscn")
