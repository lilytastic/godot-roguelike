extends Panel

func _ready():
	_initialize()
	Global.player_changed.connect(func(player): _initialize())
	Global.game_loaded.connect(func(): _initialize())
	
	%CloseButton.pressed.connect(
		func():
			print('close')
			visible = false
	)

func _initialize():
	if %Inventory:
		%Inventory.entity = Global.player
	
