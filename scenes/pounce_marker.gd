extends Marker2D

func check_end_point(pos: Vector2) -> Array:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	return space_state.intersect_point(query)
	
func is_empty(pos: Vector2) -> bool:
	return check_end_point(pos).is_empty()

func contains(pos: Vector2, object_name: String) -> bool:
	var results = check_end_point(pos)
	if results.is_empty():
		return false

	for result in results:
		if result.collider.name == object_name:
			return true
	return false
	
	
func objectnamesatspot(pos: Vector2) -> Array:
	var results = check_end_point(pos)
	var objectnames: Array[String]
	if results.is_empty():
		return []
	
	for result in results:
		if result.collider.name:
			objectnames.append(str(result.collider.name))
	
	return objectnames
	

# Check if spot is pounceoverable
func pounceoverable(pos) -> bool:
	var results = check_end_point(pos)
	var is_pounceoverable = true

	if results.is_empty():
		is_pounceoverable = false
	
	for result in results:
		if !result.collider.pounceoverable:
			is_pounceoverable = false

	return is_pounceoverable

# Check if spot is landonable
func landonable(pos) -> bool:
	var results = check_end_point(pos)
	var is_landonable = true

	if results.is_empty():
		is_landonable = false
	
	for result in results:
		if !result.collider.landonable:
			is_landonable = false
	
	return is_landonable
