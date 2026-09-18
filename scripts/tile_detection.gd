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
	return has_attribute(pos, "moveonable")

func pounceoverable(pos) -> bool:
	return has_attribute(pos, "pounceoverable")

func landonable(pos) -> bool:
	return has_attribute(pos, "landonable")

func slashthroughable(pos) -> bool:
	return has_attribute(pos, "slashthroughable")
	
func has_attribute(pos : Vector2, attribute : String) -> bool:
	var results := check_end_point(pos)
	
	if results.is_empty():
		return false

	for result in results:
		if not attribute in result.collider or not result.collider.get(attribute):
			return false
		
	return true
