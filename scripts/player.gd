extends CharacterBody2D

@onready var ray = $RayCast2D
@onready var sprite = $AnimatedSprite2D
var grid_size = 16



var inputs = {
	'ui_up': Vector2.UP,
	'ui_down': Vector2.DOWN,
	'ui_left': Vector2.LEFT,
	'ui_right': Vector2.RIGHT
}

var directional_walk_animations = {
	'ui_up': "walk up",
	'ui_down': "walk down",
	'ui_left': "walk left",
	'ui_right': "walk right"
}

func _unhandled_input(event: InputEvent) -> void:
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			var vector_pos = inputs[dir] * grid_size
			move(vector_pos)
			animation(dir)

func move(vector_pos):
	ray.target_position = vector_pos
	ray.force_raycast_update()
	if !ray.is_colliding():
		position += vector_pos

func animation(dir):
	sprite.frame = (sprite.frame + 1) % 2
	sprite.animation = directional_walk_animations[dir]
	
