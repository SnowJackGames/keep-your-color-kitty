@tool
extends StaticBody2D

@onready var tile_map_layer = $TileMapLayer
@onready var collision_shape = $CollisionShape2D

@onready var pounceoverable: = true
@onready var landonable: = true
@onready var moveonable: = true

# Possible sprites for our floor
@export var possible_source_ids: Array[int] = []:
	set(value):
		possible_source_ids = value
		update_floor()

@export var floor_size: Vector2 = Vector2(16, 16):
	set(value):
		var snapped_x = max(16, snapped(value.x, 16))
		var snapped_y = max(16, snapped(value.y, 16))
		floor_size = Vector2(snapped_x, snapped_y)
		update_floor()
		queue_redraw()

func _ready() -> void:
	update_floor()


func update_floor() -> void:
	if not is_inside_tree() or not tile_map_layer or not collision_shape:
		return

	if collision_shape.shape:
		collision_shape.shape.size = floor_size
	collision_shape.position = floor_size / 2

	tile_map_layer.clear()

	if possible_source_ids.is_empty():
		return

	var tiles_x = int(floor_size.x / 16)
	var tiles_y = int(floor_size.y / 16)

	# Randomize floor tile according to a default seed
	# This way its always the "same" random,
	# as the seed is determined by the floor's global_position
	for x in range(tiles_x):
		for y in range(tiles_y):
			var rng = RandomNumberGenerator.new()
			var cell_global_x = global_position.x + (x * 16)
			var cell_global_y = global_position.y + (y * 16)
			# This seed is the hash of the position of the floor instance
			rng.seed = hash(Vector2(cell_global_x, cell_global_y))
			var random_index = rng.randi_range(0, possible_source_ids.size() - 1)
			var random_source_id = possible_source_ids[random_index]
			tile_map_layer.set_cell(Vector2i(x, y), random_source_id, Vector2i(0, 0))
