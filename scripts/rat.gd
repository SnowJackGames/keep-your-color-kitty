extends CharacterBody2D


@onready var tile_detection : Marker2D = $TileDetection
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

@onready var pounceoverable := true
@onready var slashthroughable := false
@onready var slashable := true
@onready var landonable := true
@onready var moveonable := false
@onready var is_enemy := true

const rat_center_offset := Vector2(8,8)

var facing := "Up"
var bump_attacked : bool
var bump_attacking : bool
var cur_health : int
var declared_attack : bool
var declared_attack_pos_near
var declared_attack_pos_far
var declared_attack_direction
var declared_move_pos
var player : CharacterBody2D

var max_health := 5
var bump_slash_damage := 3
var quick_attack_damage := 3

signal FinishedMove

static var direction_dictionary = {
	"Up Left" : Vector2.UP + Vector2.LEFT,
	"Up" : Vector2.UP,
	"Up Right" : Vector2.UP + Vector2.RIGHT,
	"Right" : Vector2.RIGHT,
	"Down Right" : Vector2.RIGHT + Vector2.DOWN,
	"Down" : Vector2.DOWN,
	"Down Left" :Vector2.DOWN + Vector2.LEFT,
	"Left" : Vector2.LEFT
}

# Only 4 directions
static var simple_direction_dictionary = {
	"Up" : Vector2.UP,
	"Right" : Vector2.RIGHT,
	"Down" : Vector2.DOWN,
	"Left" : Vector2.LEFT
}

static var directional_walk_animations := {
	"Up Left" : "walk up",
	"Up" : "walk up",
	"Up Right" : "walk up",
	"Right" : "walk right",
	"Down Right" : "walk down",
	"Down" : "walk down",
	"Down Left" : "walk down",
	"Left" : "walk left"
}


signal FinishedPhase


func begin_turn() -> void:
	player = Globals.player
	declared_attack_pos_near = null
	declared_attack_pos_far = null
	declared_attack_direction = null
	declared_move_pos = null
	declared_attack = false
	bump_attacked = false
	bump_attacking = false
	phase_one()
	
func end_turn() -> void:
	pass
	
func _ready() -> void:
	cur_health = 5
	$MoveHint.hide()
	$AttackHint.hide()
	$AttackHint2.hide()

# Determine if rat should either bump slash, or move then declare attack
func phase_one() -> void:
	var is_beside_player := false
	var direction_towards_player : String
	# check surrounding 8 tiles
	var tile_detection_check : Vector2
	for direction in direction_dictionary:
		tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position + rat_center_offset
		if tile_detection.contains(tile_detection_check, "Player"):
			is_beside_player = true
			direction_towards_player = direction
	# Bump slash
	if is_beside_player:
		bump_attacking = true
		declared_move_pos = player.position
		facing = direction_towards_player
		var where_can_be_pushed = player.where_can_be_pushed(direction_towards_player)
		# declare initial position, then move position halfway towards player?
		
		if where_can_be_pushed:
			move(declared_move_pos)
			await FinishedMove
			player.take_damage(bump_slash_damage)
			player.pushed_onto(where_can_be_pushed - rat_center_offset)
		else:
			$AttackHint.global_position = declared_move_pos
			$AttackHint.show()
			await get_tree().create_timer(0.2).timeout
			player.take_damage(player.cornered_damage)
			player.take_damage(bump_slash_damage)
			$AttackHint.hide()
		# Then they damage themselves
		take_damage(bump_slash_damage)
	else:
		# Move towards player
		var closest_tile_to_player := position
		var distance_to_player := position.distance_to(player.position)
		for direction in direction_dictionary:
			tile_detection_check = direction_dictionary[direction] * Globals.grid_size + position
			if tile_detection.moveonable(tile_detection_check):
				# select the better spot
				if tile_detection_check.distance_to(player.position) < distance_to_player:
					facing = direction
					closest_tile_to_player = tile_detection_check
					distance_to_player = tile_detection_check.distance_to(player.position)
		declared_move_pos = closest_tile_to_player
		move(declared_move_pos)
		await FinishedMove
		# Declare attack
		declare_attack()
	await get_tree().create_timer(0.2).timeout
	FinishedPhase.emit()

func declare_attack() -> void:
	# iterate across all 8 directions checking 1 tile away
	# We shouldn't ever be 1 tile away from player (bc we would have bump-slashed)
	# whichever is closest to player, attack in that direction
	var direction_towards_player : String
	var distance_to_player := position.distance_to(player.position)
	var tile_detection_check : Vector2
	# Check 4 directions
	for direction in simple_direction_dictionary:
		tile_detection_check = simple_direction_dictionary[direction] * Globals.grid_size + position
		# If player is right next to us, attack there of course
		if tile_detection.player_on_tile(tile_detection_check):
			declared_attack = true
			facing = direction
			direction_towards_player = direction
			distance_to_player = tile_detection_check.distance_to(player.position)
			declared_attack_direction = direction_towards_player
			declared_attack_pos_near = tile_detection_check
			break
		# If it's a tile we can slash through or if its an enemy
		elif tile_detection.slashthroughable(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check):
			# confirm that we will be attacking
			declared_attack = true
			# If there's a tile closer, we choose that one
			if tile_detection_check.distance_to(player.position) < distance_to_player:
				facing = direction
				direction_towards_player = direction
				distance_to_player = tile_detection_check.distance_to(player.position)
				declared_attack_pos_near = tile_detection_check
	declared_attack_direction = direction_towards_player
	
	# If we can attack 1 tile away, let's see if we attack 2 tiles away
	if declared_attack:
		tile_detection_check = direction_dictionary[declared_attack_direction] * Globals.grid_size * 2 + position
		if tile_detection.player_on_tile(tile_detection_check) or tile_detection.enemy_on_tile(tile_detection_check) or tile_detection.slashthroughable(tile_detection_check):
			declared_attack_pos_far = tile_detection_check
		attack_hint()
	pass

func attack_hint() -> void:
	if declared_attack_direction:
		if declared_attack_pos_near:
			$AttackHint.global_position = declared_attack_pos_near
			$AttackHint.show()
		if declared_attack_pos_far:
			$AttackHint2.global_position = declared_attack_pos_far
			$AttackHint2.show()
			await get_tree().create_timer(0.1).timeout

func attack() -> void:
	if declared_attack:
		for attack_spot in [declared_attack_pos_near, declared_attack_pos_far]:
			if attack_spot != null:
				if tile_detection.player_on_tile(attack_spot):
					player.take_damage(quick_attack_damage)
	await get_tree().create_timer(0.2).timeout
	$AttackHint.hide()
	$AttackHint2.hide()
	FinishedPhase.emit()
		
func move(pos: Vector2):
	$MoveHint.global_position = pos
	$MoveHint.show()
	if bump_attacking:
		$AttackHint.global_position = pos
		$AttackHint.show()
	await get_tree().create_timer(0.2).timeout
	$MoveHint.hide()
	$AttackHint.hide()
	position = pos
	# Move animation, maybe hinting?
	sprite.animation = directional_walk_animations[facing]
	await get_tree().create_timer(0.15).timeout
	check_for_tile_damage()
	FinishedMove.emit()
	

func check_for_tile_damage() -> void:
	# If moved onto damaging tile, take damage
	var tile_damage : int = tile_detection.tile_damage(position)
	if tile_damage > 0:
		take_damage(tile_damage)
		
func take_damage (damage : int):
	var attack_shown = $AttackHint.visible
	var attack2_shown = $AttackHint2.visible
	if damage > 0:
		cur_health -= damage
		# Take damage animation
		if attack_shown:
			$AttackHint.hide()
		if attack2_shown:
			$AttackHint2.hide()
		hide()
		await get_tree().create_timer(0.1).timeout
		show()
		await get_tree().create_timer(0.1).timeout
		hide()
		await get_tree().create_timer(0.1).timeout
		show()

	if cur_health <= 0:
		queue_free()
	else:
		if attack_shown:
			$AttackHint.show()
		if attack2_shown:
			$AttackHint2.show()
		await get_tree().create_timer(0.2).timeout
