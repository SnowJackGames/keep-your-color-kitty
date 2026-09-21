extends Control

#signals when it's time to reload the room
signal reload_room

@onready var animation_player = $CanvasLayer/AnimationPlayer

func play_game_over():
	$CanvasLayer.show()
	animation_player.play("game_over")

func _ready() -> void:
	$CanvasLayer.hide()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	print("no longer waiting")
	reload_room.emit()
	$CanvasLayer.hide()
