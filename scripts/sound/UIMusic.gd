extends AudioStreamPlayer

export(AudioStream) var menu_music
export(float) var menu_volume = 0

export(AudioStream) var explore_music
export(float) var explore_volume = 0

export(AudioStream) var combat_music
export(float) var combat_volume = 0

export(AudioStream) var death_music
export(float) var death_volume = 0

func play_menu_music():
	stream = menu_music
	volume_db = menu_volume
	play()

func play_explore_music():
	stream = explore_music
	volume_db = explore_volume
	play()
	
func play_combat_music():
	stream = combat_music
	volume_db = combat_volume
	play()

func play_death_music():
	stream = death_music
	volume_db = death_volume
	play()
