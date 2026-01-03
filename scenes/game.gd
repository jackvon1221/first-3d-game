extends Node3D

var player_score = 0
@onready var score_label: Label = %Label
@onready var ten_point_sound: AudioStreamPlayer = $TenPointSound
@onready var diedsound: AudioStreamPlayer = %diedsound

func _ready():
	score_label.text = "SQUIBBOS: 0"
	for spawner in get_tree().get_nodes_in_group("spawner"):
		spawner.mob_spawned.connect(_on_mob_spawned)

func increase_score():
	player_score += 1
	score_label.text = "SQUIBBOS: " + str(player_score)
	if player_score % 50 == 0 and player_score > 0:
		ten_point_sound.play()
		
func do_poof(mob_global_position):
	const SMOKE_PUFF = preload("uid://cjk3frr43yesb")
	var poof = SMOKE_PUFF.instantiate()
	add_child(poof)
	poof.global_position = mob_global_position
	
func _on_mob_spawned(mob: Node3D):
	if mob.has_signal("died"):
		mob.died.connect(func on_mob_died():
			increase_score()
			do_poof(mob.global_position)
			)
		do_poof(mob.global_position)


func _on_killplane_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		diedsound.play()
		await get_tree().create_timer(0.5).timeout
		get_tree().reload_current_scene()
		
	elif "zombie" in str(body.name):  # Changed this line
		body.queue_free()
