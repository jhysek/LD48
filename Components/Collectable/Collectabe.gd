extends Area2D

export var type = "oxygen"

func _ready():
	$Sprite.texture = load("res://Components/Collectable/" + type + ".png")
	
func _on_Collectabe_body_entered(body):
	if body.is_in_group("Player"):
		collect(body)

func collect(player):
	if type == "oxygen":
		player.add_oxygen(40)	
	$Pick.play()			
	$AnimationPlayer.play("Collect")

func destroy():
	queue_free()
