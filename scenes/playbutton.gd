extends Label

func _process(delta):
	visible = int(Time.get_ticks_msec() / 500) % 2 == 0
