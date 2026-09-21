extends Control

#signals when it's time to reload the room
signal load_room

#this function waits for two signals:
# game_over, which initiates the animation
# game_resume, which closes the half black transition

@onready var game_manager = Globals.GameManager
@onready var animation_player = $CanvasLayer/AnimationPlayer

#this toggles when the process function is waiting for the animation to finish
@onready var wait = false 

func play_game_over():
	wait = true
	$CanvasLayer.show()
	animation_player.play()

func _ready() -> void:
	$CanvasLayer.hide()

func _process(_delta: float) -> void:
	if game_manager:
		print("WE SEE GAME MANAGER")
		game_manager.game_over.connect(play_game_over())
		print("MEOWWWW")
		if wait == true:
			if not animation_player.is_animation_active():
				load_room.emit
				wait = false
				game_manager.game_resume.connect($CanvasLayer.hide)
