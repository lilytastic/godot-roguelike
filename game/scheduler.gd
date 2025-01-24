class_name Scheduler

var entities: Array = []

var lastIndex = -1

# Return the next entity in sequence
func next():
	var _entities = entities.map(func(_id): return Global.ecs.entity(_id))
	var next = _entities.find(func(entity): entity.energy >= 0)
	if next != -1:
		return _entities[next]
	else:
		return null
