extends CanvasLayer

@onready var animation_player = $intro_animation

func play_intro():
	animation_player.play("opening_sequence")

func _ready() -> void:
	play_intro()
