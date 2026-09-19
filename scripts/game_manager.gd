extends Node2D

@onready var levels_scene : Node2D = $Levels
@onready var current_level : Node2D
@onready var current_level_index := -1

@onready var player_character: CharacterBody2D = $Player
@onready var ai_enemy : CharacterBody2D
@onready var ai_array := []
@onready var current_character : CharacterBody2D

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
		for ai in ai_array:
			ai.begin_turn()
			await ai.FinishedPhase
			await get_tree().create_timer(randf_range(0.1, 0.5)).timeout # stagger time btwn enemy turns
		await get_tree().create_timer(0.5).timeout # after finished
		# ENEMY MOVE / BUMP SLASH:
			# enemies move or bump slash. If they bump slashed, mark ai.bump_attacked() as true
			# 
		# ENEMY DECLARE ATTACK:
			# each enemy if they did not bump attack declares attack
	else:
		# Combat
		Globals.game_mode = 1
	#endregion
		
	#region Player Phases
	# PLAYER MOVE, PLAYER ATTACK
	current_character = player_character
	current_character.begin_turn()
	# Exploration
	if Globals.game_mode == 1:
		pass
		# If UI is up, hide it
	# Combat
	elif Globals.game_mode == 2:
		Debug.say("Combat, need UI")
		# If UI is not up, show it
		remove_object(player_character.object_destroyed_name)
	else:
		push_error("Impossible state in game_manager player phase")
	
	await current_character.FinishedTurn
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
			if !ai.bump_attacked():
				#ai enacts attack
				ai.attack()
				await ai.FinishedPhase
				ai.end_turn()
				await get_tree().create_timer(randf_range(0.1, 0.5)).timeout # random slight delay btwn enemies
		await get_tree().create_timer(0.5).timeout # after finished
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


func update_camera_target() -> void:
	Globals.level_camera = current_level.get_node("Camera2D")
	if Globals.level_camera:
		$Player/RemoteTransform2D.remote_path = Globals.level_camera.get_path()
	else:
		push_error("Current level " + current_level.name + " does not contain Camera2D")

# Deleting something, like a bomb or an enemy dying
func remove_object(name : String) -> void:
	if name:
		get_node(name).PROCESS_MODE_DISABLED

# calculate ai_array
func calc_ai_array() -> void:
	pass


func _ready() -> void:
	show()
	levels_scene.show()
	player_character.show()
	increment_active_level()
	update_camera_target()
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
		get_tree().quit()
	set_process(true)
