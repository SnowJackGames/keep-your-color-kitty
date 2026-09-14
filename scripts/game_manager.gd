extends Node2D

@onready var player_character : CharacterBody2D = $Elements/Player
@export var ai_character : CharacterBody2D
@export var current_character : CharacterBody2D

var game_over : bool = false

func next_turn ():
	Debug.say("starting turn")
	if game_over:
		return
	if current_character != null:
		current_character.end_turn()
		Debug.say("was not null")
	if (current_character == ai_character) or (current_character == null) or (ai_character == null):
		current_character = player_character
		Debug.say("set current character to player")
	else:
		current_character = ai_character

	Debug.say("beginning turn")
	current_character.begin_turn()

	if current_character == player_character:
		pass
		Debug.say("player UI stuff")
		# enable and set player ui
	else:
		Debug.say("enemy turn")
		#disable player ui
		await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
		# cast combat action
		await get_tree().create_timer(0.5).timeout
		
	await current_character.FinishedTurn
	Debug.say("finished turn")
	next_turn()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_turn()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
