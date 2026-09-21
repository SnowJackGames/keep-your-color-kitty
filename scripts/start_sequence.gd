extends Control

signal intro_done

@onready var animation_player = $intro/intro_animation

func _ready() -> void:
	$title_screen.hide()

func _process(delta: float) -> void:
	if not animation_player.is_playing():
		intro_done.emit()
		$intro/controls.hide()
