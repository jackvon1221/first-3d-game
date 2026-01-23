extends Control

@onready var master_bus := AudioServer.get_bus_index("Master")
const PAUSE_VOL_DB := -12
const NORMAL_VOL_DB := 0

func _ready():
	AudioServer.set_bus_volume_db(master_bus, PAUSE_VOL_DB)
	$ControlsPanel.visible = false
	$PLAY.grab_focus()

func _on_play_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	_resume_game()

func _on_main_menu_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	AudioServer.set_bus_volume_db(master_bus, NORMAL_VOL_DB)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("pause"):
		_resume_game()
		
func _on_controls_pressed() -> void:
	$ClickSound.play()
	$ControlsPanel.visible = !$ControlsPanel.visible

func _resume_game():
	AudioServer.set_bus_volume_db(master_bus, NORMAL_VOL_DB)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	queue_free()
