extends Node3D

var player_score = 0
@onready var score_label: Label = %Label
@onready var ten_point_sound: AudioStreamPlayer = $TenPointSound

func _ready():
	score_label.text = "SQUIBBOS: 0"
	for spawner in get_tree().get_nodes_in_group("spawner"):
		spawner.mob_spawned.connect(_on_mob_spawned)

func increase_score():
	player_score += 1
	score_label.text = "SQUIBBOS: " + str(player_score)
	if player_score % 10 == 0 and player_score > 0:
		ten_point_sound.play()

func _on_mob_spawned(mob: Node3D):
	if mob.has_signal("died"):
		mob.died.connect(increase_score)


func _on_killplane_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		get_tree().reload_current_scene()
	elif "zombie" in str(body.name):  # Changed this line
		body.queue_free()
