extends CharacterBody2D

@onready var move_ray = $MoveRay
@onready var pounce_ray = $PounceRay
@onready var sprite = $AnimatedSprite2D
@onready var facing = "up"
var grid_size = 16
var can_move = false
var can_action = false

# Might not need these if we don't support saves?
#@export var is_player : bool
#@export var cur_health : int
#@export var max_health : int

# signal OnTakeDamage (health : int)
# signal OnHeal (health : int)
# signal CantMoveHere
signal FinishedTurn
signal FinishedAction

#region Input Dictionaries
var dir_inputs = {
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

var directional_facing = {
	'ui_up': "up",
	'ui_down': "down",
	'ui_left': "left",
	'ui_right': "right"
}

var action_inputs = {
	'ui_accept': declare_slash,
	'ui_cancel': declare_pounce
}
#endregion

func begin_turn ():
	can_move = true
	can_action = true

func end_turn ():
	can_move = false
	can_action = false

func _process (_delta: float):
	if can_move == true:
		for dir in dir_inputs.keys():
			if Input.is_action_pressed(dir):
				set_process(false)
				attempt_move(dir)
				await get_tree().create_timer(0.15).timeout
				set_process(true)

	if can_action == true:
		# Exploration
		if Globals.game_mode == 1:
			for action in action_inputs.keys():
				if Input.is_action_pressed(action):
					set_process(false)
					action_inputs[action].call()
					await FinishedAction
					await get_tree().create_timer(0.3).timeout
					set_process(true)

		# Combat
		elif Globals.game_mode == 2:
			pass
		else:
			Debug.say("Impossible state")
	
	if (can_move == false) && (can_action == false):
		Debug.say("Finished turn")
		FinishedTurn.emit()

#region Move
func attempt_move(dir):
	# Initially let's face the direction
	sprite.animation = directional_walk_animations[dir]
	facing = directional_facing[dir]
	var vector_pos = dir_inputs[dir] * grid_size
	move_ray.target_position = vector_pos
	move_ray.force_raycast_update()
	if !move_ray.is_colliding():
		can_move = false
		move(vector_pos)
		# In exploration, end turn immediately after moving
		if Globals.game_mode == 1:
			end_turn()
	else:
		# check for what the ray is pointing at, in which case
		# handle particular animation and action
		Debug.say("wall")

func move(vector_pos: Vector2):
	position += vector_pos
	sprite.frame = (sprite.frame + 1) % 2
#endregion

#region Slash
func declare_slash():
	slash_hint(true)
	attempt_slash()

func attempt_slash():
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_accept" is no longer being pressed
		while Input.is_action_pressed('ui_accept'):
			# Updating direction
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
					facing = directional_facing[dir]
					slash_hint(true)
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		slash()
		
	# Combat
	elif Globals.game_mode == 2:
		# wait for "ui_accept"
		pounce()
		
	else:
		Debug.say("Impossible state in attempt_slash")

func slash_hint(shouldload: bool = false):
	if shouldload:
		# Load target hints, with focus based on var facing
		pass
	else:
		# Don't show hinting
		pass

func slash():
	Debug.say("Slash!")
	FinishedAction.emit()
	end_turn()
#endregion

#region Pounce
func declare_pounce():
	pounce_hint(true)
	attempt_pounce()

func attempt_pounce():
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_cancel" is no longer being pressed
		while Input.is_action_pressed('ui_cancel'):
			# Updating direction
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
					facing = directional_facing[dir]
					print(facing)
					pounce_hint(true)
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		pounce()

	# Combat
	elif Globals.game_mode == 2:
		# wait for "ui_accept"
		pounce()

	else:
		Debug.say("Impossible state in attempt_pounce")

func pounce_hint(shouldload: bool = false):
	if shouldload:
		# Load target hints, with focus based on var facing
		pass
	else:
		# Don't show hinting
		pass
	
func pounce():
	Debug.say("Pounce!")
	FinishedAction.emit()
	end_turn()
#endregion
	
#func take_damage (amount : int):
	#pass
	#
#func heal (amount : int):
	#pass
