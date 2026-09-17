extends Marker2D

func check_end_point(pos: Vector2) -> Array:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	return space_state.intersect_point(query)

func is_empty(pos: Vector2) -> bool:
	return check_end_point(pos).is_empty()

func contains(pos: Vector2, object_name: String) -> bool:
	var results := check_end_point(pos)
	if results.is_empty():
		return false

	for result in results:
		if result.collider.name == object_name:
			return true
	return false

func objectnamesatspot(pos: Vector2) -> Array:
	var results := check_end_point(pos)
	var objectnames : Array[String]
	if results.is_empty():
		return []
	
	for result in results:
		if result.collider.name:
			objectnames.append(str(result.collider.name))
	
	return objectnames

func tile_damage(pos) -> int:
	var results := check_end_point(pos)
	var dmg := 0
	if results.is_empty():
		return 0
	
	for result in results:
		if "tile_damage" in result.collider:
			dmg += result.collider.tile_damage
	
	return dmg
	
#region Boolean "-ables"
func moveonable(pos) -> bool:
	var results := check_end_point(pos)
	var is_moveonable := true

	if results.is_empty():
		is_moveonable = false
	
	for result in results:
		if "moveonable" in result.collider:
			if !result.collider.moveonable:
				is_moveonable = false
		else:
			is_moveonable = false

	return is_moveonable

func pounceoverable(pos) -> bool:
	var results := check_end_point(pos)
	var is_pounceoverable := true

	if results.is_empty():
		is_pounceoverable = false
	
	for result in results:
		if "pounceoverable" in result.collider:
			if !result.collider.pounceoverable:
				is_pounceoverable = false
		else:
			is_pounceoverable = false

	return is_pounceoverable

func landonable(pos) -> bool:
	var results := check_end_point(pos)
	var is_landonable := true

	if results.is_empty():
		is_landonable = false
	
	for result in results:
		if "landonable" in result.collider:
			if !result.collider.landonable:
				is_landonable = false
		else:
			is_landonable = false

	return is_landonable
#endregion

func slashthroughable(pos) -> bool:
	var results :=check_end_point(pos)
	var is_slashthroughable := true
	
	if results.is_empty():
		is_slashthroughable = false

	for result in results:
		if "slashthroughable" in result.collider:
			if !result.collider.slashthroughable:
				is_slashthroughable = false
		else:
			is_slashthroughable = false

	return is_slashthroughable
