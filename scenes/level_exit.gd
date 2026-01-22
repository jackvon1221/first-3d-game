extends Area3D

@export_file("*.tscn") var next_level_path

@onready var exit_sound = $ExitSound
var triggered := false

func _on_body_entered(body):
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		if exit_sound:
			exit_sound.play()
		await get_tree().create_timer(0.9).timeout

		GameManager.level_score = 0

		if next_level_path != "":
			get_tree().change_scene_to_file(next_level_path)
		else:
			push_error("No next level set on exit!")
