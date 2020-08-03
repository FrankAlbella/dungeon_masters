extends VBoxContainer

# VOLUME SLIDERS
onready var master_slider = $TabContainer/Audio/MasterSlider
onready var music_slider = $TabContainer/Audio/MusicSlider
onready var effects_slider = $TabContainer/Audio/EffectsSlider

# VOLUME PERCENTAGES
onready var master_label = $TabContainer/Audio/Master/Percentage
onready var music_label = $TabContainer/Audio/Music/Percentage
onready var effects_label = $TabContainer/Audio/Effects/Percentage

func _ready():
	load_settings()
	
func load_settings():
	# VISUAL
	$TabContainer/Visual/Fullscreen/Toggle.pressed = OS.window_fullscreen
	$TabContainer/Visual/Vsync/Toggle.pressed = OS.vsync_enabled
	
	# AUDIO
	# Array of audio sliders in order of audio bus index
	var sliders = [master_slider, music_slider, effects_slider]
	
	# Load all audio slider settings
	var idx = 0
	for slider in sliders:
		slider.max_value = Global.MAX_VOLUME_DB
		slider.min_value = Global.MIN_VOLUME_DB
		slider.value = AudioServer.get_bus_volume_db(idx)
		slider.step = Global.VOLUME_RANGE_DB / 100.0
		
		idx += 1
	
	# MISC
	$TabContainer/Misc/ShowFPS/Toggle.pressed = $"/root/FPSCounter".visible

func get_volume_percentage(value: float) -> String:
	return str((value + Global.VOLUME_RANGE_DB) / Global.VOLUME_RANGE_DB * 100).pad_decimals(0) + "%"
	
func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	Utility.set_config_value("visual", "fullscreen", button_pressed)

func _on_VSync_toggled(button_pressed):
	OS.vsync_enabled = button_pressed
	Utility.set_config_value("visual", "vsync", button_pressed)

func _on_volume_changed(value, index):
	Utility.change_volume(value, index)
	
	var percentage = get_volume_percentage(value)
	match index:
		Global.MASTER_AUDIO_BUS_INDEX:
			master_label.text = percentage
		Global.MUSIC_AUDIO_BUS_INDEX:
			music_label.text = percentage
		Global.EFFECT_AUDIO_BUS_INDEX:
			effects_label.text = percentage

func _on_ShowFPS_toggled(button_pressed):
	$"/root/FPSCounter".visible = button_pressed
	Utility.set_config_value("misc", "fps_counter", button_pressed)
