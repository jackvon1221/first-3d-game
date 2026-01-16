extends Area3D

func _on_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://Level-02.tscn")
