extends Control

func _process(delta):
	if Global.player:
		if Global.player.health:
			%HealthMeter.value = Global.player.health.current
			%HealthMeter.max = Global.player.health.max
			%HealthMeter.label = str(Global.player.health.current)
			%HealthMeter.label_small = '/ ' + str(Global.player.health.max)
			
