extends Control


@onready var menu_index = 0
@onready var atlas = $CanvasLayer/menu.texture
@onready var menu = $CanvasLayer/menu
@onready var controls = $CanvasLayer/controls

#signals when it's time to resume active play
signal resume_game

#signals when it's time to reload the room
signal load_room

#signals when it's time to open the title menu
signal quit_game

func show_menu():
	print("showing menu!")
	menu.show()

func hide_menu():
	print("hiding menu!")
	menu.hide()

func _ready():
	controls.hide()
	menu.hide()

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
		controls.show()
	else:
		menu_index = 0
		menu_navigation()

#this handles key input
func _process(_delta:float):
	if menu.is_visible():
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
			controls.hide()
			menu_navigation()
		elif Input.is_action_just_pressed("ui_close_dialog"):
			menu_index = 0
			controls.hide()
			menu_navigation()
		elif Input.is_action_just_pressed("ui_accept"):
			if menu_index == 0:
				resume_game.emit()
				hide_menu()
			elif menu_index == 1:
				menu_index = 4
				controls.show()
			elif menu_index == 2:
				load_room.emit()
				hide_menu()
			elif menu_index == 3:
				quit_game.emit()
				hide_menu()
			elif menu_index == 4:
				menu_index = 0
				controls.hide()
				menu_navigation()
			else:
				print("something weird happened")
				menu_index = 0
				menu_navigation()
		
		
		
		
		
		
		
