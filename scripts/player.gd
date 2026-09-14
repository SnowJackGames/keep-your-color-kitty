extends CharacterBody2D

@onready var ray = $RayCast2D
@onready var sprite = $AnimatedSprite2D
var grid_size = 16
var can_move = false
var can_action = false

signal OnTakeDamage (health : int)
signal OnHeal (health : int)
signal CantMoveHere
signal FinishedTurn

@export var is_player : bool
@export var cur_health : int
@export var max_health : int

var inputs = {
	'ui_up': Vector2.UP,
	'ui_down': Vector2.DOWN,
	'ui_left': Vector2.LEFT,
	'ui_right': Vector2.RIGHT
}

var directional_walk_animations = {
	'ui_up': "walk up",
	'ui_down': "walk down",
	'ui_left': "walk left",
	'ui_right': "walk right"
}

func begin_turn ():
	can_move = true
	can_action = true

func end_turn ():
	can_move = false
	can_action = false

func _process (delta):
	if can_move == true:
		for dir in inputs.keys():
			if Input.is_action_pressed(dir):
				declare_move(dir)
				set_process(false)
				await get_tree().create_timer(0.2).timeout
				set_process(true)

func declare_move(dir):
	var vector_pos = inputs[dir] * grid_size
	move(vector_pos)
	animation(dir)
	if can_move == false:
		FinishedTurn.emit()

func declare_action():
	can_move = false

func move(vector_pos):
	ray.target_position = vector_pos
	ray.force_raycast_update()
	if !ray.is_colliding():
		position += vector_pos
		can_move = false
	else:
		Debug.say("wall")

func animation(dir):
	sprite.frame = (sprite.frame + 1) % 2
	sprite.animation = directional_walk_animations[dir]
	
	
func take_damage (amount : int):
	pass
	
func heal (amount : int):
	pass
