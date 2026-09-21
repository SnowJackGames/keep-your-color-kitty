extends Node

@onready var title_screen = $StartSequence/title_screen
@onready var start_sequence = $StartSequence
@onready var game_manager = $GameManager
@onready var tree_ready : bool
@onready var intro = $intro_animation

func _ready() -> void:
	tree_ready = true
	game_manager.process_mode = PROCESS_MODE_DISABLED
	title_screen.process_mode = PROCESS_MODE_DISABLED
	
func title():
	title_screen.process_mode = PROCESS_MODE_INHERIT
	title_screen.show()
	
func begin():
	game_manager.process_mode = Node.PROCESS_MODE_INHERIT
	title_screen.hide()
	title_screen.process_mode = PROCESS_MODE_DISABLED
	game_manager.begin_game()

func _process(_delta: float) -> void:
	if tree_ready == true:
		title_screen.start_new_game.connect(begin)
		start_sequence.intro_done.connect(title)
