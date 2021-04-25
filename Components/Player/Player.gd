extends KinematicBody2D

enum State { 
	CONTROLLED,
	DEAD	,
}


### settings ####################################
export var is_player = true
export var inverted = false
export var GRAVITY = 50
export var SWIM_SPEED = 15000
export var ATTACK_SPEED = 10000
export var SPEED = 15000
export var BOOST = 30000
export var BOOST_CONSUMPTION = 100
export var MAXSPEED = 15050
export var OXYGEN_CAPACITY = 300
export var OXYGEN_START_LEVEL = 100
#################################################

var paused = true
var motion = Vector2(0,0) 
var attack_target
var is_moving = false
var eaten = false
var mounted_on 
var direction = Vector2(1, 0)
var state = State.CONTROLLED
var oxygen_level = OXYGEN_START_LEVEL
var oxygen_redraw_cooldown = 1
var attack_direction = Vector2(0, 0)
var counter = 0

###################################################
onready var game = get_node("/root/Game")
onready var anim = $AnimationPlayer
onready var flash_light = $Visuals/Body/HandRight/Sprite/Flashlight
onready var flash_hand = $Visuals/Body/HandRight/Sprite

func _ready():
	state = State.CONTROLLED
	_on_Timer_timeout()
	$SfxTimer.start()
		
	set_physics_process(true)
	
func alive():
	return state != State.DEAD
	

	
################################################################################
# PROCESSESS
################################################################################
func _physics_process(delta):
	if game.paused:
		if Input.is_action_just_pressed("ui_accept"):
			game.start_game()
		return
		
	if [State.CONTROLLED, State.DEAD].has(state):
		motion.y += GRAVITY * delta
		
	if state == State.CONTROLLED:
		player_control_process(delta)
		
	if is_in_group("Player") and state != State.DEAD:
		player_consume_oxygen(delta)
		
	if state == State.DEAD:
		motion.x = lerp(motion.x, 0, delta)
		motion.y = lerp(motion.y, GRAVITY * delta, delta)
		
		if is_in_group("Player") and !eaten:
			rotation_degrees += delta * 30
	
	if !eaten:
		motion = move_and_slide(motion)


func player_control_process(delta):
	var is_moving_y = false
	var is_moving_x = false
	var boost = 1
	var target_degrees = 0
	
	if is_in_group("Player"):
		if Input.is_action_pressed("ui_accept"):
			boost = BOOST * delta
			oxygen_level -= delta * BOOST_CONSUMPTION
			game.update_oxygen_indicator(oxygen_level / OXYGEN_CAPACITY * 100)
			$Visuals/Body/BoostParticles.emitting = true
		else:
			boost = 1
			$Visuals/Body/BoostParticles.emitting = false
	
	if Input.is_action_pressed('ui_left'):
		motion.x = -SPEED * delta - boost
		motion.y = 0
		target_degrees = -90
		is_moving_x = true
		
	if Input.is_action_pressed('ui_right'):
		motion.x = SPEED * delta + boost
		motion.y = 0
		target_degrees = 90
		is_moving_x = true
	
	if Input.is_action_pressed('ui_up'):
		if position.y < -1510:
			motion.y += GRAVITY * delta
		else:
			motion.y = -SPEED * delta - boost	
			target_degrees = 0
			is_moving_y = true
	
	if Input.is_action_pressed('ui_down'):
		motion.y = SPEED * delta + boost	
		target_degrees = 180
		is_moving_y = true

	var motion_direction = motion.normalized()
	
	if !is_moving_x and !is_moving_y:
		if anim and anim.is_playing():
			anim.stop()
		$Visuals.rotation_degrees = lerp($Visuals.rotation_degrees, 0, delta * 2)
		if flash_hand:
			flash_hand.rotation_degrees = lerp($Visuals/Body/HandRight/Sprite.rotation_degrees, 0, delta * 4)
	else:
		if anim and !anim.is_playing():
			anim.play("Float")
			
		var target_deg = rad2deg(motion_direction.angle()) + 90
		if $Visuals.scale.x < 0 and target_deg > 220:
			target_deg = target_deg - 360
			
		$Visuals.rotation_degrees = lerp($Visuals.rotation_degrees, target_deg, delta * 4)
		
		if flash_hand:
			flash_hand.rotation_degrees = lerp($Visuals/Body/HandRight/Sprite.rotation_degrees, -70, delta * 4)
	
	if motion.x < 0:
		$Visuals.scale.x = -0.5 #lerp($Visuals.scale.x, -0.5, delta * 10)
	else:
		 $Visuals.scale.x =  0.5 #lerp($Visuals.scale.x, 0.5, delta * 10)
	

	if !is_moving_y:
		motion.y = lerp(motion.y, GRAVITY, 4 * delta)
		
	if !is_moving_x:		
		motion.x = lerp(motion.x, 0, 4 * delta)
		
	motion.y = min(motion.y, MAXSPEED * delta + boost)


################################################################################
func object_seen(object):
	pass
				
func cannot_see_a_shit():
	pass
	
func add_oxygen(amount):
	oxygen_level = min(OXYGEN_CAPACITY, oxygen_level + amount)
	game.update_oxygen_indicator(oxygen_level / OXYGEN_CAPACITY * 100)
	oxygen_redraw_cooldown = 1
		
func player_consume_oxygen(delta):
	if oxygen_level <= 0:
		die()
	else:
		oxygen_level -= delta
	
	oxygen_redraw_cooldown -= delta
	if oxygen_redraw_cooldown <= 0:
		game.update_oxygen_indicator(oxygen_level / OXYGEN_CAPACITY * 100)
		oxygen_redraw_cooldown = 1
	
	
func die(is_eaten = false):
	if is_in_group("Player"):
		game.player_died(self)
	
	if is_in_group("Player"):
		$SfxTimer.stop()
		$CPUParticles2D.emitting = false
		$Visuals/Body/BoostParticles.emitting = false
	
	if $AnimationPlayer:
		$AnimationPlayer.stop()
	motion.x = 0
	state = State.DEAD
	
	if is_eaten:
		eaten = true
		if $Blood:
			$Blood.emitting = true

func _on_Timer_timeout():
	var sfx = $Sfx.get_node("bubble1") # + str(randi() % 2 + 1))
	sfx.pitch_scale = (randi() % 10 - 5) / 10 + 1
	sfx.play()
