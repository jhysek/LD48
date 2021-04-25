extends Node2D

var paused = true

onready var player = $Player

func _ready():
	$fishies3.hide()
	if Settings.last_checkpoint:
		player.paused = false
		paused = false
		player.position = Settings.last_checkpoint.position
		$UI/AnimationPlayer.play("Start game")
	else:
		$Player.paused = true
		$Player/AnimationPlayer.play("Float")	
	
	Transition.openScene()

func checkpoint_reached(checkpoint):
	if !Settings.last_checkpoint or checkpoint.number > Settings.last_checkpoint.number:
		Settings.last_checkpoint = {
			"position": checkpoint.position,
			"number": checkpoint.number
		}
		if checkpoint.number >= 2:
			if $fishies2:
				$fishes2.queue_free()
			$fishes3.show()
		
func update_oxygen_indicator(value):
	$CanvasLayer/UI/Oxygen.value = value

func player_died(dead_player):
	player = player
	$RestartTimer.start()

func _on_RestartTimer_timeout():
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
