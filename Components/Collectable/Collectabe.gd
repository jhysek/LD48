extends Area2D

export var type = "oxygen"

func _ready():
	pass # Replace with function body.

func _on_Collectabe_body_entered(body):
	if body.is_in_group("Player"):
		collect(body)

func collect(player):
	if type == "oxygen":
		player.add_oxygen(60)				
	$AnimationPlayer.play("Collect")

func destroy():
	queue_free()
