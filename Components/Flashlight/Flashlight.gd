extends Node2D

enum Directions {DOWN, UP, LEFT, RIGHT}

var direction = Directions.LEFT
var target_degree = 0
var enabled = true
var saw_something = false

var rays = []

func _ready():
	rays = [$Ray1, $Ray2, $Ray3]
	
	set_physics_process(true)
	
func _physics_process(delta):
	if enabled:
		for ray in rays:
			if ray.is_colliding():
				var collider = ray.get_collider()
				if collider.is_in_group("Eatable"):
					saw_something = true
					get_parent().object_seen(collider)
					return

		if saw_something:				
			saw_something = false
			get_parent().cannot_see_a_shit()
		
func turn_off():
	enabled = false
	$Light2D.enabled = false
	
func turn_on():
	enabled = true
	$Light2D.enabled = true
		
func turn_around():
	if (target_degree < 90):
		degree(180)
	else:
		degree(0)
			
func degree(target, time = 0.5):
	if target_degree != target:
		target_degree = target
		$Tween.stop_all()
		$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, target, time, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$Tween.start()
