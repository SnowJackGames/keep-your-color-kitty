extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var move = load("res://scripts/move.gd").new()
var slash = load("res://scripts/slash.gd").new()
var pounce = load("res://scripts/pounce.gd").new()
var knight = load("res://scripts/knight.gd").new()

const kitty_center_offset := Vector2(8,8)

var combat_attack_selection_index : int
var object_destroyed_name : String
var facing := "Up"
var pos_at_start_of_turn : Vector2
var on_level_exit := false
var can_move := false
var can_action := false
var just_took_damage := false

var catdamage_fx = preload("res://sound/sfx/CatDamage.mp3")    
var menu_fx1 = preload("res://sound/sfx/MenuMove.mp3")	
var menu_fx2 = preload("res://sound/sfx/MenuClick.mp3")	
var menu_fx3 = preload("res://sound/sfx/OptionsMenu.mp3")
var catattack_fx = preload("res://sound/sfx/CatAttack.mp3")


static var is_player := true
static var cornered_damage = 3
static var slash_damage = 3
static var pounce_damage = 5
static var knight_damage = 3
var cur_health : int
var max_health : int

# signal OnHeal (health : int)
# signal CantMoveHere
signal FinishedTurn
signal FinishedMove
signal FinishedAction

#region Input Dictionaries
static var dir_inputs : Dictionary[String, Vector2] = {
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


static var directional_hurt_animations := {
	'ui_up': "hurt up",
	'ui_down': "hurt down",
	'ui_left': "hurt left",
	'ui_right': "hurt right"
}

static var directional_facing : Dictionary[String, String] = {
	'ui_up': "Up",
	'ui_down': "Down",
	'ui_left': "Left",
	'ui_right': "Right"
}

static var directional_translate := {
	'Up': "ui_up",
	'Down': "ui_down",
	'Left': "ui_left",
	'Right': "ui_right"
}

var action_inputs := {
	'ui_accept': slash.declare_slash,
	'ui_cancel': pounce.declare_pounce
}



#endregion

func begin_turn():
	combat_attack_selection_index = 0
	pos_at_start_of_turn = position
	knight.reset()
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
	facing = "Up"
	sprite.animation = directional_walk_animations[directional_facing.find_key(facing)]

func _ready() -> void:
	$Targetting/Pounce.hide()
	$Targetting/Slash.hide()
	$Targetting/Move.hide()
	$Targetting/Knight.hide()
	facing = ""
	move.player = self
	move.tile_detection = tile_detection
	slash.player = self
	slash.tile_detection = tile_detection
	pounce.player = self
	pounce.tile_detection = tile_detection
	knight.player = self
	knight.tile_detection = tile_detection

func _process (_delta: float) -> void:
	if can_move == true:
		# Exploration
		if Globals.game_mode == 1:
			for dir in dir_inputs.keys():
				if Input.is_action_pressed(dir):
						set_process(false)
						move.declare_move()
						await FinishedMove
						print(position)
						set_process(true)
						break
		# Combat
		elif Globals.game_mode == 2:
			set_process(false)
			move.declare_move()
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
			await inputs_clear()
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
	await inputs_clear()
	Globalaudio.play_FX(menu_fx1)
	var chose_option := false
	var selection_just_changed := true
	while !chose_option:
		# Left
		if Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
			Globalaudio.play_FX(menu_fx2)
			if combat_attack_selection_index == 0:
				combat_attack_selection_index = 3
			else:
				combat_attack_selection_index -= 1
			selection_just_changed = true
			await get_tree().create_timer(0.05).timeout
		# Right
		if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel"):
			Globalaudio.play_FX(menu_fx2)
			combat_attack_selection_index += 1
			combat_attack_selection_index %= 4
			selection_just_changed = true
			await get_tree().create_timer(0.05).timeout
		# (A) select
		if Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
			Globalaudio.play_FX(menu_fx2)
			chose_option = true
		# (B) skip
		if Input.is_action_pressed("ui_cancel") and !Input.is_action_pressed("ui_accept") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
			Globalaudio.play_FX(menu_fx2)
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
	await inputs_clear()
	Globals.ui.hide_all()
	# Run selection selected from menu
	# Slash
	if combat_attack_selection_index == 0:
		return slash.declare_slash
	# Pounce
	elif combat_attack_selection_index == 1:
		return pounce.declare_pounce
	# Knight
	elif combat_attack_selection_index == 2:
		return knight.declare_knight
	# Skip
	else:
		return end_turn

## When given an [Array] of [String]s containing inputs [br](ex. [enum "ui_accept"], [enum "ui_cancel"] etc.),
## [br]waits for those inputs to be [i]not[/i] being pressed down [br](i.e. being "clear") before continuing.
## [br][br]If not given a particular list, defaults to: [br][[br] [enum "ui_accept"][br] [enum "ui_cancel"]
## [br] [enum "ui_up"][br] [enum "ui_down"][br] [enum "ui_left"][br] [enum "ui_right"][br]]
func inputs_clear(inputs : Array[String] = []) -> void:
	for input in inputs:
		if input is not String:
			push_error("item in Array given to await_inputs_clear() was not a string")

	var inputs_waiting_for : Array[String]
	if inputs.is_empty():
		inputs_waiting_for = [
			"ui_accept",
			"ui_cancel",
			"ui_up",
			"ui_down",
			"ui_left",
			"ui_right"
		]
	else:
		inputs_waiting_for = inputs as Array[String]

	var can_move_on
	
	for awaited_input in inputs_waiting_for:
		can_move_on = false
		while !can_move_on:
			if !Input.is_action_pressed(awaited_input):
				can_move_on = true
			await get_tree().create_timer(0.05).timeout


#region World And Entity Interactions
func check_for_tile_damage() -> void:
	# If moved onto damaging tile, take damage
	var tile_damage := 0
	tile_damage += tile_detection.tile_damage_ground(position)
	tile_damage += tile_detection.tile_damage_air(position)
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
		Globalaudio.play_FX(catdamage_fx)
		cur_health -= damage
		# Take damage animation
		var prev_animation = sprite.animation
		sprite.animation = directional_hurt_animations[directional_facing.find_key(facing)]
		sprite.frame = 0
		await get_tree().create_timer(0.06).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.06).timeout
		sprite.frame = 0
		await get_tree().create_timer(0.06).timeout
		sprite.frame = 1
		await get_tree().create_timer(0.06).timeout
		sprite.frame = 0
		await get_tree().create_timer(0.06).timeout
		sprite.animation = prev_animation
		just_took_damage = true
	#
#func heal (amount : int):
	#pass
#endregion
