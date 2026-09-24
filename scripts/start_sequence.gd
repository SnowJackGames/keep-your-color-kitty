extends Control

@onready var animation_player = $intro/intro_animation

func _ready() -> void:
	$title_screen.hide()

func _process(delta: float) -> void:
	if not animation_player.is_playing():
		$title_screen.show()
		$intro/controls.hide()
