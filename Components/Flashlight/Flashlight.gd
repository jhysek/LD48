extends Node2D

enum Directions {DOWN, UP, LEFT, RIGHT}

var direction = Directions.LEFT
var target_degree 
var enabled = true
var rays = []

func _ready():
	rays = [$Ray1, $Ray2, $Ray3]
	
	set_physics_process(true)
	
func _physics_process(delta):
	if enabled:
		for ray in rays:
			if ray.is_colliding():
				var collider = ray.get_collider()
				get_parent().object_seen(collider)
				return
		
func turn_off():
	enabled = false
	$Light2D.enabled = false
	
func turn_on():
	enabled = true
	$Light2D.enabled = true
		
func degree(target):
	if target_degree != target:
		target_degree = target
		$Tween.stop_all()
		$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, target, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$Tween.start()
