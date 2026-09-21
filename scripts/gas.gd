@tool
extends StaticBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

@onready var pounceoverable := true
@onready var landonable := true
@onready var moveonable := true
@onready var slashthroughable := true
@onready var tile_damage_air := 1

var shape_index : Dictionary[int, String] = {
	0 : "single",
	1 : "corner",
	2 : "side",
	3 : "middle"
}

# We want to be able to customize every tile instance for specific textures / rotations
@export_group("Visuals")
@export_range(0, 3) var shape : int = 0:
	set(value):
		shape = value
		_update_gas()
		
# Rotate tile in 90-degree steps 
@export_range(0, 3) var tile_rotation_steps : int = 0:
	set(value):
		tile_rotation_steps = value
		_update_gas()

func _ready() -> void:
	sprite.play()
	_update_gas()
	
func _update_gas() -> void:
	if not is_inside_tree() or not sprite:
		return
	
	# tile_map_layer.set_cell(Vector2i(0, 0), shapes, local_atlas_coords)
	sprite.animation = shape_index[shape]
	
	sprite.rotation_degrees = tile_rotation_steps * 90
	
	match tile_rotation_steps:
		0: sprite.position = Vector2(0,0)
		1: sprite.position = Vector2(Globals.grid_size,0)
		2: sprite.position = Vector2(Globals.grid_size,Globals.grid_size)
		3: sprite.position = Vector2(0,Globals.grid_size)
