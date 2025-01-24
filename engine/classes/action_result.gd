class_name ActionResult

var success: bool
var alternate: Action
var cost_energy := 0

func _init(_success: bool, opts := {}):
	success = _success
	alternate = opts.get('alternate', null)
	cost_energy = opts.get('cost_energy', 0)
