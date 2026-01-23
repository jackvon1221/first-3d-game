extends Label

var t := 0.0

func _process(delta):
	t += delta
	scale = Vector2.ONE * (1.0 + sin(t * 1.5) * 0.01)
