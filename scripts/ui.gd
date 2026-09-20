extends Control

@onready var attack_combat_atlas = $CanvasLayer/AttackCombatHover.texture

func _ready() -> void:
	hide_all()

func hide_all() -> void:
	hide()
	for node in $CanvasLayer.get_children():
		node.hide()

func attack_combat_hover(index : int) -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	# Slash
	if index == 0:
		attack_combat_atlas.region = Rect2(0,0,0,0)
	# Pounce
	elif index == 1:
		attack_combat_atlas.region = Rect2(160,0,0,0)
	# Knight
	elif index == 2:
		attack_combat_atlas.region = Rect2(320,0,0,0)
	# skip
	elif index == 3:
		attack_combat_atlas.region = Rect2(480,0,0,0)
	else:
		push_error("impossible index given to attack_combat_hover in ui.gd")
	
	$CanvasLayer/AttackCombatHover.show()


func move_combat_hover() -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	$CanvasLayer/MoveCombatHover.show()
	
func attack_combat_return_hover() -> void:
	hide_all()
	show()
	$CanvasLayer.show()
	$CanvasLayer/AttackCombatReturnHover.show()
