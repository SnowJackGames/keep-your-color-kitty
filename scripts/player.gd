extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D


const kitty_center_offset := Vector2(8,8)

var combat_attack_selection_index : int
var damage_dealt_this_turn := 0
var object_destroyed_name : String
var facing := "Up"
var pos_at_start_of_turn : Vector2
var on_level_exit := false
var can_move := false
var can_action := false

static var is_player := true
static var cornered_damage = 3
static var slash_damage = 3
static var pounce_damage = 5
static var knight_damage = 3
var cur_health : int
var max_health : int

signal OnTakeDamage (health : int)
# signal OnHeal (health : int)
# signal CantMoveHere
signal FinishedTurn
signal FinishedMove
signal FinishedAction
signal InputsClear

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

func begin_turn():
	combat_attack_selection_index = 0
	damage_dealt_this_turn = 0
	pos_at_start_of_turn = position
	can_move = true
	can_action = true

func end_turn():
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
	$Targetting/Move.hide()

func _process (_delta: float) -> void:
	if can_move == true:
		# Exploration
		if Globals.game_mode == 1:
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
						set_process(false)
						declare_move()
						await FinishedMove
						set_process(true)
						break
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
					break

		# Combat
		elif Globals.game_mode == 2:
			set_process(false)
			var selected : Callable = await attack_selection()
			selected.call()
			if selected == end_turn:
				end_turn()
			else:
				await FinishedAction
			await_inputs_clear()
			await InputsClear
			set_process(true)
			
			# check if thing was destroyed
			# if so, object_destroyed_name = that
		else:
			push_error("Impossible game_mode state")
	
	if (can_move == false) and (can_action == false):
		if tile_detection.objectnamesatspot(position + kitty_center_offset).has("Stairs"):
			on_level_exit = true
			Debug.say("on the exit")
		FinishedTurn.emit()

func attack_selection() -> Callable:
	await_inputs_clear()
	await InputsClear
	var chose_option := false
	var selection_just_changed := true
	while !chose_option:
		# Left
		if Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
			if combat_attack_selection_index == 0:
				combat_attack_selection_index = 3
			else:
				combat_attack_selection_index -= 1
			selection_just_changed = true
			await get_tree().create_timer(0.05).timeout
		# Right
		if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
			combat_attack_selection_index += 1
			combat_attack_selection_index %= 4
			selection_just_changed = true
			await get_tree().create_timer(0.05).timeout
		# (A) select
		if Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
			chose_option = true
		# (B) skip
		if Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
			combat_attack_selection_index = 3
			chose_option = true
		# Show the correct UI version
		if selection_just_changed:
			selection_just_changed = false
			if combat_attack_selection_index in range(0, 4):
				Globals.ui.attack_combat_hover(combat_attack_selection_index)
			else:
				push_error("Impossible selection index")
		# Reduce speed of loop waiting for key release
		await get_tree().create_timer(0.1).timeout
	# Wait for "let go" of other buttons
	await_inputs_clear()
	await InputsClear
	Globals.ui.hide_all()
	# Run selection selected from menu
	# Slash
	if combat_attack_selection_index == 0:
		return declare_slash
	# Pounce
	elif combat_attack_selection_index == 1:
		return declare_pounce
	# Knight
	elif combat_attack_selection_index == 2:
		return declare_slash
		# return declare_knight
	# Skip
	else:
		return end_turn

func await_inputs_clear() -> void:
	var can_move_on = false
	while !can_move_on:
		if !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
			can_move_on = true
		await get_tree().create_timer(0.05).timeout
	InputsClear.emit()

#region Move
func declare_move() -> void:
	var valid_dir := [] # "Up", etc
	for dir in directional_facing: # directional_facing: ui_up -> Up
		var valid_target := true
		var tile_detection_check := (dir_inputs[dir] * Globals.grid_size * 1) + position + kitty_center_offset
		if !tile_detection.moveonable(tile_detection_check):
			valid_target = false
		if valid_target:
			valid_dir.append(directional_facing[dir])
	
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
			if Input.is_action_pressed(dir):
				# Make sure we're not trying to move in two directions at once
				var is_multiple_buttons := false
				for dir2 in dir_inputs.keys():
					if (dir != dir2) and Input.is_action_pressed(dir2):
						is_multiple_buttons = true
				if !is_multiple_buttons:
					## Attempt move
					facing = directional_facing[dir]
					if directional_facing[dir] in valid_dir:
						can_move = false
						sprite.animation = directional_walk_animations[dir]
						move(dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 1)
					else:
						Debug.say("Invalid move")
						await get_tree().create_timer(0.15).timeout
						FinishedMove.emit()
						break
				else:
					# Won't let player move two ways at once
					await get_tree().create_timer(0.15).timeout
					FinishedMove.emit()
					break

	#Combat
	elif Globals.game_mode == 2:
		Globals.ui.move_combat_hover()
		var can_process_move := false
		var should_move := false
		while !can_process_move:
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir) and valid_dir.has(directional_facing[dir]):
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
				can_process_move = true
			
			await get_tree().create_timer(0.1).timeout
		await_inputs_clear()
		await InputsClear
		move_hint([], false)
		can_move = false
		if should_move:
			move(dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 1)
		else:
			FinishedMove.emit()
	
	else:
		push_error("Impossible state in attempt_move")


func move_hint(valid_dir: Array, shouldload: bool) -> void:
	var move_ui := "Targetting/Move/"
	if shouldload:
		var directions := ["Up", "Right", "Down", "Left"]
		for dir in directions:
			if valid_dir.has(dir):
				if facing == dir:
					get_node(move_ui + dir + "Focused").show()
					get_node(move_ui + dir + "Unfocused").hide()
				else:
					get_node(move_ui + dir + "Unfocused").show()
					get_node(move_ui + dir + "Focused").hide()
			else:
				get_node(move_ui + dir + "Focused").hide()
				get_node(move_ui + dir + "Unfocused").hide()
		# Reveal after processing visibility of sub-layers
		get_node(move_ui).show()
	else:
		get_node(move_ui).hide()

func move(vector_pos: Vector2):
	if Globals.game_mode == 1:
		can_action = false
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
		
		# Check if enemy is near
		if tile_detection.enemy_on_tile(tile_detection_check_near):
			valid_dir.append(directional_facing[dir] + "Near") # ex. "UpNear"
			valid_dir_without_near_or_far.append(directional_facing[dir])
		# Check if near is slashthroughable
		elif tile_detection.slashthroughable(tile_detection_check_near):
			# if so, is enemy far
			if tile_detection.enemy_on_tile(tile_detection_check_far):
				valid_dir.append(directional_facing[dir] + "Far") # ex. "UpFar"
				valid_dir_without_near_or_far.append(directional_facing[dir])
			# otherwise, is far slashthroughable
			elif tile_detection.slashthroughable(tile_detection_check_far):
				valid_dir.append(directional_facing[dir] + "Far") # ex. "UpFar"
				valid_dir_without_near_or_far.append(directional_facing[dir])
			# otherwise, near is slashthroughable but not far
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
		await_inputs_clear()
		await InputsClear
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
					break
			# Reduce speed of loop waiting for key release
			await get_tree().create_timer(0.1).timeout
		slash(valid_dir)
		
	# Combat
	elif Globals.game_mode == 2:
		Globals.ui.attack_combat_return_hover()
		var chose_option := false
		var go_back := false
		while !chose_option:
			for dir in dir_inputs.keys():
				# (A) accept
				if Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
					chose_option = true
					break
				# (B) cancel
				elif Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept"):
					chose_option = true
					go_back = true
					break
				elif Input.is_action_pressed(dir) and !Input.is_action_pressed("ui_accept")and !Input.is_action_pressed("ui_cancel"):
					facing = directional_facing[dir]
					sprite.animation = directional_walk_animations[dir]
					slash_hint(valid_dir, true)
					break
			await get_tree().create_timer(0.1).timeout
		await_inputs_clear()
		await InputsClear
		if go_back:
			slash_hint([], false)
			FinishedAction.emit()
		else:
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
	Globals.ui.hide_all()
	slash_hint([], false)
	var damage_spot : Vector2
	# Near slash
	if valid_dir.has((facing + "Near")) and !valid_dir.has((facing + "Far")):
		Debug.say("Slash " + facing + " Near!")
		damage_spot = (dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 1) + position
		await tile_detection.damage_object(damage_spot, slash_damage)
		# Animate near slash
		await get_tree().create_timer(0.3).timeout
	# Far slash
	elif valid_dir.has((facing + "Far")) and !valid_dir.has((facing + "Near")):
		Debug.say("Slash " + facing + " Far!")
		damage_spot = (dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 2) + position
		await tile_detection.damage_object(damage_spot, slash_damage)
		# Animate far slash
		await get_tree().create_timer(0.3).timeout

	elif valid_dir.has((facing + "Near")) and valid_dir.has((facing + "Far")):
		push_error("Cannot slash both near and far")
	
	else:
		push_error("Asked to slash this direction but cannot")
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
		await_inputs_clear()
		await InputsClear
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
		Globals.ui.attack_combat_return_hover()
		var chose_option := false
		var go_back := false
		while !chose_option:
			for dir in dir_inputs.keys():
				# (A) accept
				if Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
					chose_option = true
					break
				# (B) cancel
				elif Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept"):
					chose_option = true
					go_back = true
					break
				elif Input.is_action_pressed(dir) and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
					facing = directional_facing[dir]
					sprite.animation = directional_walk_animations[dir]
					pounce_hint(valid_dir, true)
					break
			await get_tree().create_timer(0.1).timeout
		await_inputs_clear()
		await InputsClear
		if go_back:
			pounce_hint([], false)
			FinishedAction.emit()
		else:
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
	Globals.ui.hide_all()
	pounce_hint([], false)
	# Facing: Up -> directional_facing: ui_up -> dir_inputs: Vector2.UP
	var pounce_vector_pos : Vector2 = dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 3
	var damage_spot = (dir_inputs[directional_facing.find_key(facing)] * Globals.grid_size * 3) + position
	# We animate moving
	position += pounce_vector_pos
	await tile_detection.damage_object(damage_spot, pounce_damage)
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
	
# Check to see where entity can be pushed
func where_can_be_pushed(source_direction) -> Variant:
	var push_spot = null
	var tile_detection_check : Vector2
	if source_direction == "Up":
		tile_detection_check = (Vector2.UP) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Down":
		tile_detection_check = (Vector2.DOWN) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Left":
		tile_detection_check = (Vector2.LEFT) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Right":
		tile_detection_check = (Vector2.RIGHT) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Up Left":
		tile_detection_check = ((Vector2.UP) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Up Right":
		tile_detection_check = ((Vector2.UP) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Down Left":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.LEFT)) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	elif source_direction == "Down Right":
		tile_detection_check = ((Vector2.DOWN) + (Vector2.RIGHT)) * Globals.grid_size * 1 + position + kitty_center_offset
		if tile_detection.moveonable(tile_detection_check):
			push_spot = tile_detection_check
	else:
		push_error("received impossible direction: " + source_direction)
	return push_spot

func take_damage (damage : int):
	if damage > 0:
		cur_health -= damage
		# Take damage animation
		hide()
		await get_tree().create_timer(0.1).timeout
		show()
		await get_tree().create_timer(0.1).timeout
		hide()
		await get_tree().create_timer(0.1).timeout
		show()
		await get_tree().create_timer(0.2).timeout
		OnTakeDamage.emit()
	#
#func heal (amount : int):
	#pass
#endregion
