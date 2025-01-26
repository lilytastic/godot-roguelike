class_name Meter

var _current = 1
var current:
	get: return _current
	set(value): _current = min(max, max(0, value))
var max = 1
var penalty = 0.0

func _init(_max: int, opts := {}):
	max = _max
	current = opts.get('current', _max)
	penalty = opts.get('penalty', penalty)
	
func deduct(amount: int, raisePenalty := false):
	current = max(0, current - amount)
	print('deducted by: ', amount, ' -- now: ', current)
	if raisePenalty:
		penalty += amount / 10

func removePenalty():
	penalty = 0
