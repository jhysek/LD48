extends KinematicBody2D

enum State { 
	CONTROLLED,
	MOUNTED,
	FISH,
	ATTACKING,
	DEAD	,
}


### settings ####################################
export var is_player = true
export var agressive = false
export var GRAVITY = 50
export var SWIM_SPEED = 15000
export var ATTACK_SPEED = 10000
export var SPEED = 15000
export var BOOST = 30000
export var BOOST_CONSUMPTION = 100
export var MAXSPEED = 15050
export var OXYGEN_CAPACITY = 300
#################################################

var motion = Vector2(0,0) 
var attack_target
var is_moving = false
var eaten = false
var mounted_on 
var direction = Vector2(1, 0)
var state = State.CONTROLLED
var oxygen_level = OXYGEN_CAPACITY
var oxygen_redraw_cooldown = 1
var attack_direction = Vector2(0, 0)

###################################################
onready var game = get_node("/root/Game")
onready var anim = $AnimationPlayer
onready var flash_light = $Visuals/Body/HandRight/Sprite/Flashlight
onready var flash_hand = $Visuals/Body/HandRight/Sprite

func _ready():
	if !is_player:
		state = State.FISH
		flash_light = $Flashlight
	else:
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
	if [State.CONTROLLED, State.DEAD].has(state):
		motion.y += GRAVITY * delta
	
	if state == State.FISH:
		fish_process(delta)
		
	if state == State.CONTROLLED:
		player_control_process(delta)
	
	if state == State.MOUNTED:
		player_mounted_process(delta)

		
	if is_in_group("Player") and state != State.DEAD:
		player_consume_oxygen(delta)
		
	if state == State.DEAD:
		motion.x = lerp(motion.x, 0, delta)
		motion.y = lerp(motion.y, GRAVITY * delta, delta)
		
		if is_in_group("Player") and !eaten:
			rotation_degrees += delta * 30
	
	if state != State.MOUNTED and !eaten:
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

func fish_process(delta):
	motion.x = direction.x * SWIM_SPEED * delta
	motion.y = lerp(motion.y, 0, delta * 3)

func fish_attack_process(delta):
	motion = attack_direction * ATTACK_SPEED * delta

func player_mounted_process(delta):
	if Input.is_action_pressed("ui_accept"):
		unmount()
	
	if mounted_on:
		position = lerp(position, mounted_on.get_node("MountPosition").global_position, delta * 8)

################################################################################

################################################################################
func object_seen(object):
	print("I can see something ", state)
	if [State.FISH].has(state):
		state = State.ATTACKING
		print("I can see something.. ", state)
		if object.is_in_group("Eatable") and object.state != object.State.DEAD:
			print(" And it's eatable...")
			attack(object)

	if state == State.CONTROLLED:
		if object.is_in_group("Fish"):
			print("Look! A Fish!")
			
func cannot_see_a_shit():
	if state == State.ATTACKING:
		state = State.FISH
	if direction.x < 0:
		flash_light.degree(-180, 1)
	else:
		flash_light.degree(0)

func attack(object):
	attack_direction = position.direction_to(object.position)	 
	print("ATTACK: ", attack_direction)
	$Tween.interpolate_property(self, 'position', position, object.position + position.direction_to(object.position) * 50, 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	$Sfx/attack1.play()

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
	game.player_died()
	
	$SfxTimer.stop()
	$AnimationPlayer.stop()
	$Visuals/Body/BoostParticles.emitting = false
	$CPUParticles2D.emitting = false
	motion.x = 0
	state = State.DEAD
	
	if is_eaten:
		eaten = true
		$Blood.emitting = true

func eat(victim):
	print(victim, " has been eaten... ")
	victim.die(true)
	var new_parent = self
	game.remove_child(victim)
	new_parent.add_child(victim)
	victim.position = Vector2(0,0)
	
	
func mount(driver):
	print("mounting the player on ", driver)
	# Let's control the fish now
	mounted_on = driver
	driver.state = State.CONTROLLED
	
	# Player will just sit down and relax
	state = State.MOUNTED
	collision_layer = 2
	collision_mask = 2
	flash_light.turn_off()
	
func unmount():
	if mounted_on:
		print("Unmounting the player...")
		# Let fish go...
		mounted_on.get_unmounted()
		mounted_on = null
		$UnmountTween.interpolate_property(self, "position", position, position - Vector2(0, 100), 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$UnmountTween.start()
		
func get_unmounted():
	state = State.FISH
	$Visuals.scale.x = 1
	direction = Vector2(1, 0)
	flash_light.degree(0)
	
func turn_around():
	if state == State.FISH:
		direction.x *= -1
		$Visuals.scale.x *= -1
		flash_light.turn_around()
	
func _on_HeadArea_body_entered(body):
	if [State.ATTACKING, State.FISH].has(state):
		if agressive and body.is_in_group("Player") and !body.eaten:
			$AnimationPlayer.play("Attack")
			eat(body)	
			
		if body is TileMap:
			turn_around()
			print("A WALL!")


func _on_TailArea_body_entered(body):
	if body.is_in_group("Player"):
		body.mount(self)	


func _on_UnmountTween_tween_completed(object, key):
		# Player is controllable again
		state = State.CONTROLLED
		collision_layer = 1
		collision_mask = 1
		flash_light.turn_on()


func _on_Timer_timeout():
	var sfx = $Sfx.get_node("bubble1") # + str(randi() % 2 + 1))
	sfx.pitch_scale = (randi() % 10 - 5) / 10 + 1
	sfx.play()
