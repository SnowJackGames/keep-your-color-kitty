extends Control

#this code is just the pause menu itself 
#it doesn't handle pausing the game process or opening/closing itself
#because i figured that would be handled by game manager
#you might want to add a pause_game signal that this connects to


@onready var menu_index = 0
@onready var atlas = $menu.texture

#signals when it's time to resume active play
signal game_resume

#signals when it's time to reload the room
signal load_room

#signals when it's time to open the title menu
signal quit_game

func _ready():
	$controls.hide()

#this keeps track of which button you're hovering over
func menu_navigation():
	if menu_index == 0:
		atlas.region = Rect2(0,0,0,0)
	elif menu_index == 1:
		atlas.region = Rect2(160, 0, 0, 0)
	elif menu_index == 2:
		atlas.region = Rect2(320, 0, 0, 0)
	elif menu_index == 3:
		atlas.region = Rect2(480, 0, 0, 0)
	elif menu_index == 4:
		$controls.show()
	else:
		menu_index = 0
		menu_navigation()

#this handles key input
func _process(_delta:float):
	if Input.is_action_just_pressed("ui_up"):
		if menu_index >= 1:
			menu_index -= 1
		elif menu_index == 0:
			menu_index = 3
		menu_navigation()
	elif Input.is_action_just_pressed("ui_down"):
		if menu_index <= 2:
			menu_index += 1
		elif menu_index == 3:
			menu_index = 0
		menu_navigation()
	elif Input.is_action_just_pressed("ui_cancel"):
		menu_index = 0
		$controls.hide()
		menu_navigation()
	elif Input.is_action_just_pressed("ui_close_dialog"):
		menu_index = 0
		$controls.hide()
		menu_navigation()
	elif Input.is_action_just_pressed("ui_accept"):
		if menu_index == 0:
			game_resume.emit()
		elif menu_index == 1:
			menu_index = 4
			$controls.show()
		elif menu_index == 2:
			load_room.emit()
		elif menu_index == 3:
			quit_game.emit()
		elif menu_index == 4:
			menu_index = 0
			$controls.hide()
			menu_navigation()
		else:
			print("something weird happened")
			menu_index = 0
			menu_navigation()
		
		
		
		
		
		
		
