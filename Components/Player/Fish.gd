extends KinematicBody2D

enum State { 
	FISH,
	ATTACKING,
	DEAD	,
}


### settings ####################################
export var is_player = false
export var agressive = false
export var swimming = true
export var inverted = false
export var GRAVITY = 50
export var SWIM_SPEED = 15000
export var ATTACK_SPEED = 10000
export var SPEED = 15000
export var BOOST = 30000
export var BOOST_CONSUMPTION = 100
export var MAXSPEED = 15050
#################################################

var paused = true
var motion = Vector2(0,0) 
var attack_target
var is_moving = false
var eaten = false
var direction = Vector2(1, 0)
var state = State.FISH
var attack_direction = Vector2(0, 0)
var counter = 0
var victim_in_range
export var disable_attack = false

###################################################
onready var game = get_node("/root/Game")
onready var anim = $AnimationPlayer
onready var flash_light = $Visuals/Flashlight

func _ready():
	state = State.FISH
	if inverted:
		turn_around()
	set_physics_process(true)
	
func alive():
	return state != State.DEAD
	
################################################################################
# PROCESSESS
################################################################################
func _physics_process(delta):
	if game.paused:
		return
				
	if state == State.FISH:
		fish_process(delta)
			
	if state == State.DEAD:
		motion.x = lerp(motion.x, 0, delta)
		motion.y = lerp(motion.y, GRAVITY * delta, delta)
		
	motion = move_and_slide(motion)


func fish_process(delta):
	motion.y = lerp(motion.y, 0, delta * 5)
	
	if swimming:
		counter += delta * 5
		motion.x = direction.x * SWIM_SPEED * delta
		$Visuals.position.y = sin(counter) * 10  #lerp(motion.y, sin(delta ) * 100, delta * 3)
		$Visuals.rotation_degrees = sin(counter / 2) * 1
	
	
func fish_attack_process(delta):
	motion = attack_direction * ATTACK_SPEED * delta


################################################################################
func object_seen(object):
	if [State.FISH].has(state) and agressive:
		state = State.ATTACKING
		if object.is_in_group("Eatable") and object.state != object.State.DEAD:
			attack(object)
			
func cannot_see_a_shit():
	if state == State.ATTACKING:
		state = State.FISH
		
func attack(object):
	attack_direction = position.direction_to(object.position)	 
	$Tween.interpolate_property(self, 'position', position, object.position + position.direction_to(object.position) * 50, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	$Sfx/attack1.play()
	
func die(is_eaten = false):	
	if $AnimationPlayer:
		$AnimationPlayer.stop()
	motion.x = 0
	state = State.DEAD
	
	if is_eaten:
		eaten = true
		if $Blood:
			$Blood.emitting = true
		
func eat(victim):
	victim.die(true)
	var new_parent = $Visuals/HeadArea
	game.remove_child(victim)
	victim.show_behind_parent = true
	new_parent.add_child(victim)
	
	victim.position = Vector2(0,0)
	victim.collision_mask = 2
	victim.collision_layer = 2
	
	state = State.FISH
	if !victim.is_player:
		victim.queue_free()

		
func turn_around():
	if state == State.FISH:
		direction.x *= -1
		$Visuals.scale.x *= -1
	
func _on_HeadArea_body_entered(body):
	if [State.ATTACKING, State.FISH].has(state):
		if agressive and body.is_in_group("Eatable") and !body.eaten:
			$AnimationPlayer.play("Attack")
			eat(body)	
			
		if swimming and body is TileMap:
			turn_around()

func prepare_for_attack():
	$AttackTimer.start()
	$AnimationPlayer.play("Attack prep")

func _on_DetectArea_body_entered(body):
	if body.is_in_group("Player"):
		victim_in_range = body
		prepare_for_attack()
		
func _on_AttackTimer_timeout():
	if victim_in_range and !disable_attack:
		attack(victim_in_range)

func _on_DetectArea_body_exited(body):
	if body.is_in_group("Player") and body.alive():
		$AnimationPlayer.stop()
		$AttackTimer.stop()
		victim_in_range = null
		$AnimationPlayer.play_backwards("Attack prep")
