extends Control

func _process(time: float) -> void:
	var min = 0.0
	var max = 1.0
	var diff = (max - min) / 2.0
	var speed = 0.003
	modulate = Color(1, 1, 1, (min + diff) + sin(Time.get_ticks_msec() * speed) * diff)
