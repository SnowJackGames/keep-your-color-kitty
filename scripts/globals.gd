extends Node

const grid_size := 16

# 0 is null
# 1 is exploration
# 2 is combat
var game_mode := 0

@onready var level_camera : Camera2D
