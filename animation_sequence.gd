class_name AnimationSequence

var length = 1.0
var sequence := []
var progress = 0.0

func _init(_sequence := [], _length := 1.0):
	sequence = _sequence
	length = _length
	
func process(delta: float) -> Dictionary:
	progress = min(progress + delta, length)
	# 0.5 -> [0, 1, 2]
	var index = progress / length * (sequence.size() - 1)
	var min = floor(index)
	var max = ceil(index)
	var step = index - min
	var starting_position = sequence[min].position
	var next_position = sequence[max].position
	return {
		'position': starting_position.lerp(next_position, step)
	}
