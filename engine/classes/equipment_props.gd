class_name EquipmentProps

var slots := []

func _init(props: Dictionary):
	slots = props.get('slots', []).map(
		func(slot): 
			if slot is Dictionary and slot.has('id'):
				return slot.id 
			return slot
	)
