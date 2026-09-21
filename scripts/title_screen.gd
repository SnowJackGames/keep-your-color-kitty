extends CanvasLayer

#signals when it's time to start from level -1
signal start_new_game

#signals when it's time to load the saved file
signal load_save

#these keep track of which screen is being shown
@onready var screen = "controls"
@onready var menu = 1
@onready var button = ""

# menu navigation function for 2 button menu
func menu_navigation():
	if button == "load":
		$mm2_load.show()
	elif button == "new":
		$mm2_load.hide()

func _ready() -> void:
	$main_menu_1.hide()
	$mm2_load.hide()
	$mm2_new.hide()
	
	#checks if there's a save
	var current_level_index = -1 #load_game()
	
	#if there's no save, show the new player menu
	if current_level_index <= 0:
		$main_menu_1.show()
		
	#if there is a save, show the returning player menu
	elif current_level_index >= 1:
		menu = 2
		$mm2_load.show()
		$mm2_new.show()
		button = "load"

func _process(_delta: float) -> void:
	if screen == "controls":
		if Input.is_action_just_pressed("ui_accept"):
			$controls.hide()
			if menu == 1: screen = "menu1"
			if menu == 2: screen = "menu2"
	if screen == "menu1":
		if Input.is_action_just_pressed("ui_accept"):
			print("start new game!")
			start_new_game.emit()
			hide()
	if screen == "menu2":
		if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_left"):
			if button == "new":
				button = "load"
			elif button == "load":
				button = "new"
			menu_navigation()
		if Input.is_action_just_pressed("ui_accept"):
			if button == "new":
				start_new_game.emit()
			elif button == "load":
				load_save.emit()
