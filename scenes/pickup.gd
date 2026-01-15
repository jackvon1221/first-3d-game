extends Node3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		$PickupSound.play()

		var game = get_tree().get_first_node_in_group("game")
		if game:
			game.do_poof(global_position)
			game.add_point_from_pickup()

		# Disable collision immediately so the sound doesn't double-trigger
		$Area3D.monitoring = false

		# Let the sound finish before freeing the node
		await $PickupSound.finished
		queue_free()
