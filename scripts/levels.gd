extends Node2D


@onready var level_order = [
	$Level1,
	$Level2
]

# Disable all levels at first
func _ready() -> void:
	for level in level_order:
		level.visible = false
		level.process_mode = PROCESS_MODE_DISABLED
