extends Node2D

@onready var levels_scene : Node2D = $Levels
@onready var current_level : Node2D
@onready var current_level_index := -1

@onready var player_character: CharacterBody2D = $Player
@onready var ai_enemy : CharacterBody2D
@onready var ai_array : Array[CharacterBody2D] = []

var game_over := false


func next_turn () -> void:
	Debug.say("starting turn")
	if game_over:
		return
	
	#region Enemy Phases
	# Check to see if there's any ai_enemys (enemies). put them in ai_array based on position
	calc_ai_array()
	if ai_array:
		# Exploration
		Globals.game_mode = 2
		await get_tree().create_timer(0.2).timeout
		for ai in ai_array:
			ai.begin_turn()
			await ai.FinishedPhase
			await get_tree().create_timer(randf_range(0.1, 0.2)).timeout # stagger time btwn enemy turns
		Debug.say("AI completed phase one")
	else:
		# Combat
		Globals.game_mode = 1
	#endregion
		
	#region Player Phases
	calc_ai_array() # in case any AI died during their turn
	if !ai_array:
		Globals.game_mode = 1
	
	# PLAYER MOVE, PLAYER ATTACK
	player_character.begin_turn()
	## Exploration
	#if Globals.game_mode == 1:
		#pass
		## If UI is up, hide it
	## Combat
	#elif Globals.game_mode == 2:
		## If UI is not up, show it
		#pass
	#else:
		#push_error("Impossible state in game_manager player phase")
	update_camera_target()
	await player_character.FinishedTurn
	# Current enemy in ai_array takes player_character.damage_dealt
	
	# redefine ai_array
	#endregion

	#region Next Enemy Phases
	# Recalc array after player turn
	calc_ai_array()
	if ai_array:
		# Disable player UI
		# ENEMY ATTACK
		for ai in ai_array:
			if ai.declared_attack:
				#ai enacts attack
				ai.attack()
				await ai.FinishedPhase
				ai.end_turn()
				await get_tree().create_timer(randf_range(0.1, 0.2)).timeout # random slight delay btwn enemies
		await get_tree().create_timer(0.1).timeout # after finished
	else:
		Globals.game_mode = 1
	#endregion
	
	# Unlock stairs
	if Globals.game_mode == 1:
		if current_level.get_node("Elements/Stairs"):
			current_level.get_node("Elements/Stairs").unlock()

	if player_character.on_level_exit:
		increment_active_level()

	Debug.say("finished turn\n--------")
	next_turn()


func increment_active_level() -> void:
	player_character.reset_status()

	if current_level != null:
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_level_index += 1
	
	if current_level_index >= levels_scene.level_order.size():
		Debug.say("Finished last level")
		get_tree().quit()
	
	else:
		current_level = get_node("Levels/" + str(levels_scene.level_order[current_level_index]))
		current_level.visible = true
		current_level.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Move player to starting position of level
		player_character.position = current_level.player_start_position
	update_camera_target()


func update_camera_target() -> void: 	
	$Player/RemoteTransform2D.remote_path = NodePath("")  
	
	await get_tree().process_frame

	Globals.level_camera = current_level.get_node("Camera2D")
	
	if Globals.level_camera: 
		Globals.level_camera.make_current()
		$Player/RemoteTransform2D.use_global_coordinates = true
		$Player/RemoteTransform2D.remote_path = Globals.level_camera.get_path()
		$Player/RemoteTransform2D.force_update_cache()
		Globals.level_camera.global_position = $Player.global_position
		print($Player/RemoteTransform2D.remote_path)
	else: 
		push_error("Current level " + current_level.name + " does not contain Camera2D")



# calculate ai_array
func calc_ai_array() -> void:
	var unsorted_array : Array[CharacterBody2D] = []
	# search to see if any enemies
	
	for child in current_level.find_children("*", "CharacterBody2D"):
		if "is_enemy" in child or child.get("is_enemy"):
			unsorted_array.append(child)

	# sort them left to right, top to bottom
	# but for now
	ai_array = unsorted_array

func _ready() -> void:
	Globals.player = $Player
	Globals.ui = $UI
	show()
	levels_scene.show()
	player_character.show()
	increment_active_level()
	next_turn()

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	set_process(false)
	# To prevent OnTakeDamage crashing,
	# I think we might have to make sure that character damage cannot occur on the
	# very first frame that the game is loaded in? Which hopefully shouldn't be a problem
	await player_character.OnTakeDamage
	Debug.say("Health: %s / %s" % [player_character.cur_health, player_character.max_health])
	# Game Over
	if player_character.cur_health <= 0:
		player_character.hide()
		get_tree().quit()
	set_process(true)
