extends Node2D

var paused = true

func _ready():
	$Player/AnimationPlayer.play("Float")
	$Player/SfxTimer.start()
	
func player_died(foo):
	pass

func remove_fish():
	$BigScaryFish.queue_free()
	
func _on_Timer_timeout():
	Transition.switchTo("res://Scenes/Game.tscn")
