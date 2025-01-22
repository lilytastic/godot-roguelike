extends Panel

func _ready():
	Global.player_changed.connect(func(player): _initialize())
	_initialize()

func _initialize():
	%InventoryTab.entity = Global.player
