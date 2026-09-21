extends Node

@onready var title_screen = $StartSequence/title_screen
@onready var game_manager = $GameManager
@onready var tree_ready : bool

func _ready() -> void:
	tree_ready = true
func begin():
	game_manager.begin_game()

func _process(delta: float) -> void:
	if tree_ready == true:
		title_screen.start_new_game.connect(begin)
