extends Node3D

@onready var score_label: Label = %Label
@onready var ten_point_sound: AudioStreamPlayer = $TenPointSound
@onready var diedsound: AudioStreamPlayer = %diedsound



func _ready():
	# Make sure the label shows the carried-over score
	update_score_label()


func add_point_from_pickup():
	GameManager.score += 1
	update_score_label()
	if GameManager.score % 10 == 0:
		ten_point_sound.play()


func update_score_label():
	score_label.text = "SQUIBBOS: " + str(GameManager.score)


func do_poof(mob_global_position):
	const SMOKE_PUFF = preload("uid://cjk3frr43yesb")
	var poof = SMOKE_PUFF.instantiate()
	add_child(poof)
	poof.global_position = mob_global_position


func _on_mob_spawned(mob: Node3D):
	if mob.has_signal("died"):
		mob.died.connect(func on_mob_died():
			do_poof(mob.global_position)
		)


func _on_killplane_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		diedsound.play()
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()

	elif "zombie" in str(body.name):
		body.queue_free()
