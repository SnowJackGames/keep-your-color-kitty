extends CharacterBody2D

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
	$AnimatedSprite2D.play()
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)
			animation(dir)

func move(dir):
	position += inputs[dir] * grid_size

func animation(dir):
	$AnimatedSprite2D.play(directional_walk_animations[dir])
