extends Area2D


export var number = 1
onready var game = get_node("/root/Game")


func _on_Checkpoint_body_entered(body):
	if body.is_in_group("Player"):
		game.checkpoint_reached(self)
		
