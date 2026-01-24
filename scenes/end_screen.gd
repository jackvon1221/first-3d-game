extends Control

var allow_exit := false

@onready var score_label: Label = $ScoreLabel

func _ready():
	score_label.text = "YOU GOT " + str(GameManager.score) + " SQUIBBOS!"


	get_tree().create_timer(10.0).timeout.connect(func():
		allow_exit = true
	)

func _input(event):
	if allow_exit and event.is_pressed():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
