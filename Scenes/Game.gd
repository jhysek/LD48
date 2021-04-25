extends Node2D

var paused = true

func _ready():
	$Player.paused = true
	$Player/AnimationPlayer.play("Float")	
	Transition.openScene()
	
func update_oxygen_indicator(value):
	$CanvasLayer/UI/Oxygen.value = value

func player_died():
	$RestartTimer.start()

func _on_RestartTimer_timeout():
	Transition.switchTo("res://Scenes/Game.tscn")	

func start_game():
	if paused:
		Settings.started = true
		$UI/AnimationPlayer.play("Start game")
		paused = false
