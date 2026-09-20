extends Node

const grid_size := 16

# 0 is null
# 1 is exploration
# 2 is combat
var game_mode := 0

@onready var level_camera : Camera2D

@onready var player : CharacterBody2D
#@onready var remote_transform_2D : CharacterBody2D

@onready var ui : Control

@onready var entity_to_damage : CharacterBody2D


# Deleting something, like a bomb or an enemy dying
func remove_object(object_full_path : String) -> void:
	if object_full_path:
		get_node(object_full_path).queue_free()
