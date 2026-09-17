extends Node2D

var player_start_position : Vector2

# based on top left of square of *center* 16 x 16 tile of player
# i.e. the player's actual position tile (actual sprite might be larger than 16 x 16)
@export var set_player_start_position : Vector2 = Vector2(0,0):
	set(value):
		player_start_position = value
