extends Node2D

var paused = true

var last_checkpoint = null

func _ready():
	$Player.paused = true
	$Player/AnimationPlayer.play("Float")	
	Transition.openScene()

func checkpoint_reached(checkpoint):
	if !last_checkpoint or checkpoint.number > last_checkpoint.number:
		print("CHECKPOINT! ", checkpoint.number)
		last_checkpoint = checkpoint
		
func update_oxygen_indicator(value):
	$CanvasLayer/UI/Oxygen.value = value

func player_died():
	$RestartTimer.start()

func _on_RestartTimer_timeout():
	if last_checkpoint:
		$Player.revive_at(last_checkpoint)
		Transition.openScene()
	else:
		Transition.switchTo("res://Scenes/Game.tscn")	

func start_game():
	if paused:
		Settings.started = true
		$UI/AnimationPlayer.play("Start game")
		paused = false


func _on_Finish_body_entered(body):
	if body.is_in_group("Player"):
		game_finished()
		
		
func game_finished():
	print("FINISHED")


func _on_FinishTimer_timeout():
	paused = true
	Transition.switchTo("res://Scenes/Finish.tscn")
