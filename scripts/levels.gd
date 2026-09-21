extends Node2D


@onready var level_order = [
	$Level7,
	$Exploration2,
	$Level8, 
	$Level9,
	$Level10,
	$Level11,
	$Level12,
	$Level13,
	$Level14,
	$Level15,
	$Level16,
	$Level17,
	$Level18,
	$Level1,
	$Level2,
	$Level3,
	$Level4,
	$Level5,
	$Exploration1,
	
]

# Disable all levels at first
func _ready() -> void:
	for level in level_order:
		level.visible = false
		level.process_mode = PROCESS_MODE_DISABLED
