extends Node2D

func _ready():
	pass # Replace with function body.

func update_oxygen_indicator(value):
	$CanvasLayer/UI/Oxygen.value = value
