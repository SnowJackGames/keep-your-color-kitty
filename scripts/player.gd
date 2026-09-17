extends CharacterBody2D

@onready var move_marker: = $MoveMarker as Marker2D
@onready var pounce_marker: Marker2D = $PounceMarker
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing: = "up"
var grid_size: = 16
var can_move: = false
var can_action: = false

# Might #@export these if we support saves?
#var is_player : bool
var cur_health : int
var max_health : int

signal OnTakeDamage (health : int)
# signal OnHeal (health : int)
# signal CantMoveHere
signal FinishedTurn
signal FinishedAction

#region Input Dictionaries
var dir_inputs: = {
	'ui_up': Vector2.UP,
	'ui_down': Vector2.DOWN,
	'ui_left': Vector2.LEFT,
	'ui_right': Vector2.RIGHT
}

var directional_walk_animations: = {
	'ui_up': "walk up",
	'ui_down': "walk down",
	'ui_left': "walk left",
	'ui_right': "walk right"
}

var directional_facing: = {
	'ui_up': "Up",
	'ui_down': "Down",
	'ui_left': "Left",
	'ui_right': "Right"
}

var action_inputs: = {
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
	
func _ready() -> void:
	$Targetting/Pounce.hide()
	cur_health = 15
	max_health = 15

func _process (_delta: float) -> void:
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
					Debug.say("saw finished")
					await get_tree().create_timer(0.3).timeout
					set_process(true)

		# Combat
		elif Globals.game_mode == 2:
			pass
		else:
			push_error("Impossible game_mode state")
	
	if (can_move == false) && (can_action == false):
		FinishedTurn.emit()

#region Move
func attempt_move(dir) -> void:
	# Initially let's face the direction
	sprite.animation = directional_walk_animations[dir]
	facing = directional_facing[dir]
	
	var kitty_center_offset: = Vector2(8,8)
	var move_marker_check: Vector2 = (dir_inputs[dir] * grid_size * 1) + position + kitty_center_offset
	if move_marker.moveonable(move_marker_check):
		can_move = false
		move(dir_inputs[dir] * grid_size * 1)
		if Globals.game_mode == 1:
			end_turn()
	else:
		var objlist: String
		for obj in move_marker.objectnamesatspot(move_marker_check):
			objlist += obj + " "
		Debug.say(objlist)


func move(vector_pos: Vector2):
	position += vector_pos
	sprite.frame = (sprite.frame + 1) % 2
#endregion

#region Slash
func declare_slash() -> void:
	slash_hint(true)
	attempt_slash()

func attempt_slash() -> void:
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_accept" is no longer being pressed
		while Input.is_action_pressed('ui_accept'):
			# Updating direction
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
					facing = directional_facing[dir]
					sprite.animation = directional_walk_animations[dir]
					slash_hint(true)
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		slash()
		
	# Combat
	elif Globals.game_mode == 2:
		# wait for "ui_accept" to send action
		pounce()
		
	else:
		push_error("Impossible state in attempt_slash")

func slash_hint(shouldload: bool = false) -> void:
	if shouldload:
		# Load target hints, with focus based on var facing
		pass
	else:
		# Don't show hinting
		pass

func slash() -> void:
	Debug.say("Slash " + facing + " !")
	end_turn()
	FinishedAction.emit()
#endregion

#region Pounce
func declare_pounce() -> void:
	# First check to see in what directions we can pounce
	var valid_dir: = [] # "Up", etc
	for dir in directional_facing: # directional_facing: ui_up -> Up
		var valid_target: = true
		var pounce_marker_check: Vector2
		var kitty_center_offset: = Vector2(8,8)
		# move pounce_marker to each increasing spot towards the target
		for i in range(1, 3):
			pounce_marker_check = (dir_inputs[dir] * grid_size * i) + position + kitty_center_offset
			if !pounce_marker.pounceoverable(pounce_marker_check):
				valid_target = false
				break
		
		pounce_marker_check = (dir_inputs[dir] * grid_size * 4) + position + kitty_center_offset
		if !pounce_marker.landonable(pounce_marker_check):
			valid_target = false
			
		if valid_target:
			valid_dir.append(directional_facing[dir])

		# Now, we check more *specifically* what is in the way with PounceMarker
		# move pounce_marker to each increasing spot towards the target
		# check if whatever is there can be pounced over (create attribute for each object for this)
		# if 1 and 2 away cannot be pounced over, or 3 away cannot be landed on,
		# then cannot pounce
	
	if ! valid_dir.is_empty():
		# Make sure we're not facing an illegal direction...
		if !valid_dir.has(facing):
			# Face a random valid direction
			facing = valid_dir[randi_range(0, (valid_dir.size() - 1))]
			# ex. facing: Up -> directional_facing: ui_up -> directional_walk_animations: walk up
			sprite.animation = directional_walk_animations[directional_facing.find_key(facing)]
		pounce_hint(valid_dir, true)
		attempt_pounce(valid_dir)
	else:
		Debug.say("No valid pounce target!")
		# Animate "no valid target"
		while Input.is_action_pressed('ui_cancel'):
			# Wait for button to be let go
			# Reduce speed of loop waiting for key release
			# Also, you need a non-zero amount of time awaiting FinishedAction
			await get_tree().create_timer(0.1).timeout
		FinishedAction.emit()

func attempt_pounce(valid_dir: Array) -> void:
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_cancel" is no longer being pressed
		while Input.is_action_pressed('ui_cancel'):
			# Updating direction
			for dir in dir_inputs: # dir_inputs: ui_up -> Vector2.up -> walk up
				if Input.is_action_pressed(dir):
					if valid_dir.has(directional_facing[dir]): # directional_facing: ui_up -> Up
						facing = directional_facing[dir]
						sprite.animation = directional_walk_animations[dir]
						pounce_hint(valid_dir, true)
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.05).timeout
		pounce()

	# Combat
	elif Globals.game_mode == 2:
		# wait for "ui_accept"
		pounce()

	else:
		push_error("Impossible state in attempt_pounce")
		FinishedAction.emit()

func pounce_hint(valid_dir: Array, shouldload: bool) -> void:
	var pounce_ui: = "Targetting/Pounce/"
	if shouldload:
		get_node(pounce_ui).show()
		var directions: = ["Up", "Right", "Down", "Left"]
		for dir in directions:
			if valid_dir.has(dir):
				get_node(pounce_ui + dir + "Partial").show()
				if facing == dir:
					get_node(pounce_ui + dir + "Focused").show()
					get_node(pounce_ui + dir + "Unfocused").hide()
				else:
					get_node(pounce_ui + dir + "Unfocused").show()
					get_node(pounce_ui + dir + "Focused").hide()
			else:
				get_node(pounce_ui + dir + "Partial").hide()
				get_node(pounce_ui + dir + "Focused").hide()
				get_node(pounce_ui + dir + "Unfocused").hide()
	else:
		get_node(pounce_ui).hide()
	
func pounce() -> void:
	# Turn off hint
	pounce_hint([], false)
	# Facing: Up -> directional_facing: ui_up -> dir_inputs: Vector2.UP
	var pounce_vector_pos: Vector2 = dir_inputs[directional_facing.find_key(facing)] * grid_size * 3
	# We animate moving
	# We deal damage to whatever is there
	# i.e anything there takes a damage
	# We move there
	position += pounce_vector_pos
	Debug.say("Pounce " + facing + " !")
	end_turn()
	FinishedAction.emit()
#endregion
	
#func take_damage (amount : int):
	#pass
	#
#func heal (amount : int):
	#pass
