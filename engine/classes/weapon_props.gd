class_name WeaponProps

var type: String
var damage: Array
var range: int
var speed: float
var weaponskills: Array

func _init(props: Dictionary):
	type = props.get('type', 'bludgeon')
	damage = props.get('damage', [5, 5])
	range = props.get('range', 1)
	speed = props.get('speed', 1)
	weaponskills = props.get('weaponskills', [])
	
func save():
	return {
		"type": "pierce",
		"damage": [3, 11],
		"range": 12,
		"speed": 0.8,
		"weaponskills": [ "shoot" ],
	}
