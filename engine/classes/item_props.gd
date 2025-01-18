class_name ItemProps

var slots := [] # Where this item can be equipped
var weight := 0

func _init(props: Dictionary):
	slots = props.get('wearable', {}).get('slots', [])
	weight = props.get('storage', {}).get('weight', 0)
