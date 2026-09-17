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
	if ai_array:
		# Exploration
		Globals.game_mode = 2
		# ENEMY MOVE / BUMP ATTACK:
			# enemies move or bump attack. If they bump attacked, mark them as such
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
	else:
		push_error("Impossible state in game_manager player phase")
	
	await current_character.FinishedTurn
	#endregion

	#region Next Enemy Phases
	if ai_array:
		# ENEMY ATTACK
		# Disable player UI
		# Each enemy in ai_array that has declared an attack then attacks
		await get_tree().create_timer(randf_range(0.5, 1.5)).timeout # between attack?
		await get_tree().create_timer(0.5).timeout # after finished
		pass
	#endregion

	print(player_character.position)
	Debug.say("finished turn\n--------")
	next_turn()


func set_active_level() -> void:
	if current_level != null:
		current_level.visible = false
		current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_level_index += 1
	
	if current_level_index >= levels_scene.level_order.size():
		Debug.say("Finished last level")
		get_tree().quit()
	
	current_level = get_node("Levels/" + str(levels_scene.level_order[current_level_index]))
	current_level.visible = true
	current_level.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Move player to starting position of level
	print(player_character.position)
	player_character.position = current_level.player_start_position
	print(player_character.position)


func update_camera_target() -> void:
	Globals.level_camera = current_level.get_node("Camera2D")
	if Globals.level_camera:
		$Player/RemoteTransform2D.remote_path = Globals.level_camera.get_path()
	else:
		push_error("Current level " + current_level.name + " does not contain Camera2D")
	# Fixed code


func _ready() -> void:
	levels_scene.show()
	set_active_level()
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
