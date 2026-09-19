extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

const kitty_center_offset := Vector2(8,8)

var damage_dealt_this_turn := 0
var object_destroyed_name : String
var facing := "Up"
var pos_at_start_of_turn : Vector2
var on_level_exit := false
var can_move := false
var can_action := false

#var is_player : bool
var cur_health : int
var max_health : int

signal OnTakeDamage (health : int)
# signal OnHeal (health : int)
# signal CantMoveHere
signal FinishedTurn
signal FinishedMove
signal FinishedAction

#region Input Dictionaries
static var dir_inputs : Dictionary[String, Vector2]= {
	'ui_up': Vector2.UP,
	'ui_down': Vector2.DOWN,
	'ui_left': Vector2.LEFT,
	'ui_right': Vector2.RIGHT
}

static var directional_walk_animations := {
	'ui_up': "walk up",
	'ui_down': "walk down",
	'ui_left': "walk left",
	'ui_right': "walk right"
}

static var directional_facing := {
	'ui_up': "Up",
	'ui_down': "Down",
	'ui_left': "Left",
	'ui_right': "Right"
}

var action_inputs := {
	'ui_accept': declare_slash,
	'ui_cancel': declare_pounce
}
#endregion

func begin_turn ():
	damage_dealt_this_turn = 0
	pos_at_start_of_turn = position
	can_move = true
	can_action = true

func end_turn ():
	# If you end your turn in a damaging tile
	# but hadn't moved onto it during the turn, then you now take damage
	if position == pos_at_start_of_turn:
		check_for_tile_damage()
	can_move = false
	can_action = false
	
func reset_status() -> void:
	cur_health = 15
	max_health = 15
	on_level_exit = false
	Debug.say("Full health!")

func _ready() -> void:
	$Targetting/Pounce.hide()
	$Targetting/Slash.hide()

func _process (_delta: float) -> void:
	if can_move == true:
		# Exploration
		if Globals.game_mode == 1:
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
					set_process(false)
					declare_move()
					await FinishedMove
					print("moved")
					set_process(true)
		# Combat
		elif Globals.game_mode == 2:
			set_process(false)
			declare_move()
			await FinishedMove
			set_process(true)
		
		else:
			push_error("Impossible game_mode state")
		
	if can_action == true:
		# Exploration
		if Globals.game_mode == 1:
			for action in action_inputs.keys():
				if Input.is_action_pressed(action):
					set_process(false)
					action_inputs[action].call()
					await FinishedAction
					set_process(true)

		# Combat
		elif Globals.game_mode == 2:
			pass
			# check if thing was destroyed
			# if so, object_destroyed_name = that
		else:
			push_error("Impossible game_mode state")
	
	if (can_move == false) and (can_action == false):
		if tile_detection.objectnamesatspot(position + kitty_center_offset).has("Stairs"):
			on_level_exit = true
			print("on the exit")
		FinishedTurn.emit()

#region Move
func declare_move() -> void:
	var valid_dir := [] # "Up", etc
	for dir in directional_facing: # directional_facing: ui_up -> Up
		var valid_target := true
		var tile_detection_check := (dir_inputs[dir] * Globals.grid_size * 1) + position + kitty_center_offset
		if !tile_detection.moveonable(tile_detection_check):
			valid_target = false
		if valid_target:
			valid_dir.append(dir)
	
	if !valid_dir.is_empty():
		# In Combat
		if Globals.game_mode == 2:
			move_hint(valid_dir, true)
		attempt_move(valid_dir)
	
	# No valid movement
	else:
		Debug.say("No valid movement")
		await get_tree().create_timer(0.1).timeout
		can_move = false
		FinishedAction.emit()


func attempt_move(valid_dir) -> void:
	# Exploration
	if Globals.game_mode == 1:
		for dir in dir_inputs.keys():
			var is_multiple_buttons := false
			if Input.is_action_pressed(dir):
				# Make sure we're not trying to move in two directions at once
				for dir2 in dir_inputs.keys():
					if dir != dir2 and Input.is_action_pressed(dir2):
						is_multiple_buttons = true
						break
				if !is_multiple_buttons:
					# Attempt move
					print(valid_dir)
					if dir in valid_dir:
						can_move = false
						move(dir_inputs[dir] * Globals.grid_size * 1)
					else:
						# can't move that way
						await get_tree().create_timer(0.15).timeout
						FinishedMove.emit()
				else:
					await get_tree().create_timer(0.15).timeout
					FinishedMove.emit()
	#Combat
	elif Globals.game_mode == 2:
		var can_process_move := false
		var should_move := false
		while !can_process_move:
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir) and dir in valid_dir:
					# face correct direction, update move_hint
					sprite.animation = directional_walk_animations[dir]
					facing = directional_facing[dir]
					move_hint(valid_dir, true)
			
			# pressing (A) while facing a valid direction
			if Input.is_action_pressed("ui_accept") and facing in valid_dir:
				# hide the combat move UI
				should_move = true
				can_process_move = true
			
			# pressing (B) skips movement
			if Input.is_action_pressed("ui_cancel"):
				# hide the combat move UI
				can_process_move = true
			
			await get_tree().create_timer(0.1).timeout
	# Hide move UI
	
		if should_move:
			move_hint([], false)
			can_move = false
			move(dir_inputs[directional_facing[facing]] * Globals.grid_size * 1)
		else:
			FinishedAction.emit()
	
	else:
		push_error("Impossible state in attempt_move")

func move_hint(valid_dir: Array, shouldload: bool) -> void:
	#var move_ui := "Targetting/Move/"
	#if shouldload:
		#var directions := ["Up", "Right", "Down", "Left"]
		#for dir in directions:
			#if valid_dir.has(dir):
				#if facing == dir:
					#get_node(move_ui + dir + "Focused").show()
					#get_node(move_ui + dir + "Unfocused").hide()
				#else:
					#get_node(move_ui + dir + "Unfocused").show()
					#get_node(move_ui + dir + "Focused").hide()
			#else:
				#get_node(move_ui + dir + "Focused").hide()
				#get_node(move_ui + dir + "Unfocused").hide()
		## Reveal after processing visibility of sub-layers
		#get_node(move_ui).show()
	#else:
		#get_node(move_ui).hide()
		pass

func move(vector_pos: Vector2):
	position += vector_pos
	sprite.frame = (sprite.frame + 1) % 2
	# Move animation
	await get_tree().create_timer(0.15).timeout
	check_for_tile_damage()
	FinishedMove.emit()
#endregion

#region Slash
func declare_slash() -> void:
	# Check to see in what directions we can slash, and how far
	var valid_dir := [] # "UpNear", "UpFar", etc
	var valid_dir_without_near_or_far := []
	for dir in directional_facing: # ui_up -> Up
		var tile_detection_check_near : Vector2 = (dir_inputs[dir] * Globals.grid_size * 1) + position + kitty_center_offset
		var tile_detection_check_far : Vector2 = (dir_inputs[dir] * Globals.grid_size * 2) + position + kitty_center_offset
		
		# We can't go "far" until we first go "near".
		# But if we can go "far" then there's no need to go "near"
		# You can never be both "near" and "far",
		# But "near" is on the way to "far".
		if tile_detection.slashthroughable(tile_detection_check_near):
			if tile_detection.slashthroughable(tile_detection_check_far):
				valid_dir.append(directional_facing[dir] + "Far") # ex. "UpFar"
				valid_dir_without_near_or_far.append(directional_facing[dir])
			else:
				valid_dir.append(directional_facing[dir] + "Near") # ex. "UpNear"
				valid_dir_without_near_or_far.append(directional_facing[dir])
	
	if !valid_dir.is_empty():
		# Make sure we're not facing an illegal direction...
		if !(valid_dir.has(facing + "Near") or valid_dir.has(facing + "Far")):
			# Face a random valid direction
			facing = valid_dir_without_near_or_far[randi_range(0, (valid_dir_without_near_or_far.size() - 1))]
			# ex. facing: Up -> directional_facing: ui_up -> directional_walk_animations: walk up
			sprite.animation = directional_walk_animations[directional_facing.find_key(facing)]
			
		slash_hint(valid_dir, true)
		attempt_slash(valid_dir)
	else:
		Debug.say("No valid slash target!")
		# Animate shake head
		await get_tree().create_timer(0.3).timeout
		while Input.is_action_pressed('ui_accept'):
			# Wait for button to be let go
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		FinishedAction.emit()

func attempt_slash(valid_dir: Array) -> void:
	# Exploration
	if Globals.game_mode == 1:
		# Until "ui_accept" is no longer being pressed
		while Input.is_action_pressed('ui_accept'):
			# Updating direction
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
					facing = directional_facing[dir]
					sprite.animation = directional_walk_animations[dir]
					slash_hint(valid_dir, true)
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		slash(valid_dir)
		
	# Combat
	elif Globals.game_mode == 2:
		# wait for "ui_accept" to send action
		slash(valid_dir)
		
	else:
		push_error("Impossible state in attempt_slash")

func slash_hint(valid_dir: Array, shouldload: bool = false) -> void:
	var slash_ui := "Targetting/Slash/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			# Only show near hints
			if valid_dir.has(dir + "Near") and !valid_dir.has(dir + "Far"):
				# Hide the fars
				get_node(slash_ui + dir + "FarFocused").hide()
				get_node(slash_ui + dir + "FarUnfocused").hide()
				if facing == dir:
					get_node(slash_ui + dir + "NearFocused").show()
					get_node(slash_ui + dir + "NearUnfocused").hide()
				else:
					get_node(slash_ui + dir + "NearUnfocused").show()
					get_node(slash_ui + dir + "NearFocused").hide()

			# show near and far hints
			elif valid_dir.has(dir + "Far") and !valid_dir.has(dir + "Near"):
				if facing == dir:
					get_node(slash_ui + dir + "NearFocused").show()
					get_node(slash_ui + dir + "FarFocused").show()
					get_node(slash_ui + dir + "NearUnfocused").hide()
					get_node(slash_ui + dir + "FarUnfocused").hide()
				else:
					get_node(slash_ui + dir + "NearUnfocused").show()
					get_node(slash_ui + dir + "FarUnfocused").show()
					get_node(slash_ui + dir + "NearFocused").hide()
					get_node(slash_ui + dir + "FarFocused").hide()
			
			# Error state
			elif valid_dir.has(dir + "Near") and valid_dir.has(dir + "Far"):
				push_error("cannot slash both near and far")
			
			# Hide everything
			else:
				get_node(slash_ui + dir + "NearFocused").hide()
				get_node(slash_ui + dir + "FarFocused").hide()
				get_node(slash_ui + dir + "NearUnfocused").hide()
				get_node(slash_ui + dir + "FarUnfocused").hide()
		# Reveal after processing visibility of sub-layers
		get_node(slash_ui).show()

	else:
		get_node(slash_ui).hide()

func slash(valid_dir: Array) -> void:
	slash_hint([], false)
	if valid_dir.has((facing + "Near")) and !valid_dir.has((facing + "Far")):
		Debug.say("Slash " + facing + " Near!")
		# Animate near slash
		await get_tree().create_timer(0.3).timeout

	elif valid_dir.has((facing + "Far")) and !valid_dir.has((facing + "Near")):
		Debug.say("Slash " + facing + " Far!")
		# Animate far slash
		await get_tree().create_timer(0.3).timeout

	elif valid_dir.has((facing + "Near")) and valid_dir.has((facing + "Far")):
		push_error("Cannot slash both near and far")
	
	else:
		push_error("Asked to slash this direction but cannot")
	
	damage_dealt_this_turn = 3
	end_turn()
	FinishedAction.emit()
#endregion

#region Pounce
func declare_pounce() -> void:
	# First check to see in what directions we can pounce
	var valid_dir := [] # "Up", etc
	for dir in directional_facing: # directional_facing: ui_up -> Up
		var valid_target := true
		var tile_detection_check : Vector2
		# move tile_detection to each increasing spot towards the target
		# if 1 and 2 away cannot be pounced over, or 3 away cannot be landed on,
		# then cannot pounce
		for i in range(1, 2):
			tile_detection_check = (dir_inputs[dir] * Globals.grid_size * i) + position + kitty_center_offset
			if !tile_detection.pounceoverable(tile_detection_check):
				valid_target = false
				break
		
		tile_detection_check = (dir_inputs[dir] * Globals.grid_size * 3) + position + kitty_center_offset
		if !tile_detection.landonable(tile_detection_check):
			valid_target = false
			
		if valid_target:
			valid_dir.append(directional_facing[dir])
	
	if !valid_dir.is_empty():
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
		# Animate shake head
		await get_tree().create_timer(0.3).timeout
		while Input.is_action_pressed('ui_cancel'):
			# Wait for button to be let go
			# Reduce speed of loop waiting for key release
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

func pounce_hint(valid_dir: Array, shouldload: bool) -> void:
	var pounce_ui := "Targetting/Pounce/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			if valid_dir.has(dir):
				if facing == dir:
					get_node(pounce_ui + dir + "Focused").show()
					get_node(pounce_ui + dir + "Unfocused").hide()
				else:
					get_node(pounce_ui + dir + "Unfocused").show()
					get_node(pounce_ui + dir + "Focused").hide()
			else:
				get_node(pounce_ui + dir + "Focused").hide()
				get_node(pounce_ui + dir + "Unfocused").hide()
		# Reveal after processing visibility of sub-layers
		get_node(pounce_ui).show()
	else:
		get_node(pounce_ui).hide()
	
func pounce() -> void:
	pounce_hint([], false)
	# Facing: Up -> directional_facing: ui_up -> dir_inputs: Vector2.UP
	var pounce_vector_pos : Vector2 = dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 3
	# We animate moving
	position += pounce_vector_pos
	await get_tree().create_timer(0.3).timeout
	# We move there [we can make this smoother]
	# We deal damage to whatever is there
	# i.e anything there takes a damage
	Debug.say("Pounce " + facing + " !")

	# If pounced onto damaging spot, take damage
	check_for_tile_damage()
	damage_dealt_this_turn = 5
	end_turn()
	FinishedAction.emit()
#endregion

#region World And Entity Interactions
func check_for_tile_damage() -> void:
	# If moved onto damaging tile, take damage
	var tile_damage : int = tile_detection.tile_damage(position)
	if tile_damage > 0:
		take_damage(tile_damage)

func pushed_onto(pos : Vector2) -> void:
	position = pos
	check_for_tile_damage()

func take_damage (damage : int):
	if damage > 0:
		cur_health -= damage
		# Take damage animation, slowdown
		await get_tree().create_timer(0.6).timeout
		OnTakeDamage.emit()
	#
#func heal (amount : int):
	#pass
#endregion
