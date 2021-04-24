extends Node2D

func _ready():
	Transition.openScene()
	
func update_oxygen_indicator(value):
	$CanvasLayer/UI/Oxygen.value = value

func player_died():
	$RestartTimer.start()

func _on_RestartTimer_timeout():
	Transition.switchTo("res://Scenes/Game.tscn")	
