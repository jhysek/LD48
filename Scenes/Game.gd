extends Node2D

var paused = true

onready var player = $Player

func _ready():
	$fishes3.hide()
	if Settings.last_checkpoint:
		player.paused = false
		paused = false
		player.position = Settings.last_checkpoint.position
		$UI/AnimationPlayer.play("Start game")
		
		if Settings.last_checkpoint.number >= 2:
			if $fishies2:
				$fishes2.queue_free()
			$fishes3.show()
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
		$UI/Button.queue_free()
		$UI/AnimationPlayer.play("Start game")
		paused = false


func _on_Finish_body_entered(body):
	if body.is_in_group("Player"):
		game_finished()
		
		
func game_finished():
	$FinishTimer.start()

func _on_FinishTimer_timeout():
	paused = true
	Settings.last_checkpoint = null
	Transition.switchTo("res://Scenes/Finish.tscn")

func _on_Button_mouse_entered():
	$UI/click.play()


func _on_Button_mouse_exited():
	$UI/click.play()


func _on_Button_button_down():
	$UI/click.play()
