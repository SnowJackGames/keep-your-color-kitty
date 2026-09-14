extends Node
var debug = true
func say(message: String) -> void:
	if debug:
		print("[%s] %s" % [Time.get_time_string_from_system(), message])
