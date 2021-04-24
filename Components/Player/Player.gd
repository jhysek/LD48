extends KinematicBody2D

enum State { 
	CONTROLLED,
	HOOKED,
	FISH,
	DEAD	,
}


### settings ####################################
export var is_player = true
export var GRAVITY = 50
export var SWIM_SPEED = 15000
export var MAXSPEED = 15050
export var OXYGEN_CAPACITY = 300
#################################################

var motion = Vector2(0,0) 
var is_moving = false
var state = State.CONTROLLED
var oxygen_level = OXYGEN_CAPACITY
var oxygen_redraw_cooldown = 1

###################################################
onready var game = get_node("/root/Game")
onready var flash_light = $Flashlight

func _ready():
	if !is_player:
		state = State.FISH
	else:
		state = State.CONTROLLED
		
	set_physics_process(true)
	

################################################################################
# PROCESSESS
################################################################################
func _physics_process(delta):
	if state == State.FISH:
		fish_process(delta)
	else:
		motion.y += GRAVITY * delta
	
	if state == State.CONTROLLED:
		player_control_process(delta)
	
	if state != State.DEAD:
		player_consume_oxygen(delta)
	
	motion = move_and_slide(motion)


func player_control_process(delta):
	is_moving = false
	
	if Input.is_action_pressed('ui_left'):
		motion.x = -SWIM_SPEED * delta
		motion.y = 0
		is_moving = true
		
	if Input.is_action_pressed('ui_right'):
		motion.x = SWIM_SPEED * delta
		motion.y = 0
		is_moving = true
	
	if Input.is_action_pressed('ui_up'):
		motion.y = -SWIM_SPEED * delta
		is_moving = true
	
	if Input.is_action_pressed('ui_down'):
		motion.y = SWIM_SPEED * delta
		is_moving = true

	if !is_moving:
		motion.y = lerp(motion.y, GRAVITY, 4 * delta)		
		motion.x = lerp(motion.x, 0, 4 * delta)

	var direction = motion.normalized()
	flash_light.degree(rad2deg(direction.angle()))
	
	motion.y = min(motion.y, MAXSPEED * delta)

func fish_process(delta):
	motion.x = SWIM_SPEED * delta
	motion.y = lerp(motion.y, 0, delta * 3)

################################################################################

################################################################################
func object_seen(object):
	if state == State.FISH:
		if object.is_in_group("Eatable"):
			print("I WILL EAT YOU!")

	if state == State.CONTROLLED:
		if object.is_in_group("Fish"):
			print("Look! A Fish!")

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
	
	
func die():
	motion.x = 0
	state = State.DEAD
