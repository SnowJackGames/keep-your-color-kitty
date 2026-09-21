extends AudioStreamPlayer



func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	play()
	
func play_music_level(track):
		_play_music(track)
		
	
	
