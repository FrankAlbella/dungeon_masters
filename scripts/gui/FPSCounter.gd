extends Label

func _ready():
	set_process(true)
	
func _process(_delta):
	text = "FPS: " + str(Engine.get_frames_per_second())
	text += "\nSeed: " + str(Gamestate.get_rng_seed())
	text += "\nPlayer Count: " + str(Gamestate.get_player_count())
	text += "\nIs Server: " + str(Gamestate.is_server)
