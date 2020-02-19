extends VBoxContainer

const MAX_VOLUME_DB = 0
const MIN_VOLUME_DB = -60
var VOLUME_RANGE_DB = abs(MAX_VOLUME_DB) + abs(MIN_VOLUME_DB)

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
	OS.window_fullscreen = Utility.get_config_value("visual", "fullscreen", true)
	$TabContainer/Visual/Fullscreen/Toggle.pressed = OS.window_fullscreen
	
	OS.vsync_enabled = Utility.get_config_value("visual", "vsync", true)
	$TabContainer/Visual/Vsync/Toggle.pressed = OS.vsync_enabled
	
	# AUDIO
	master_slider.value = int(Utility.get_config_value("audio", "master_volume", 0.0))
	music_slider.value = int(Utility.get_config_value("audio", "music_volume", 0.0))
	effects_slider.value = int(Utility.get_config_value("audio", "effects_volume", 0.0))
	
	# MISC
	$"/root/FPSCounter".visible = Utility.get_config_value("misc", "fps_counter", true)
	$TabContainer/Misc/ShowFPS/Toggle.pressed = $"/root/FPSCounter".visible
	
	
func get_volume_percentage(value: float) -> String:
	return str((value + 60) / 60 * 100).pad_decimals(0) + "%"
	
func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	Utility.set_config_value("visual", "fullscreen", button_pressed)

func _on_VSync_toggled(button_pressed):
	OS.vsync_enabled = button_pressed
	Utility.set_config_value("visual", "vsync", button_pressed)

func _on_volume_changed(value, index):
	AudioServer.set_bus_volume_db(index, value)
	
	var percentage = get_volume_percentage(value)
	match index:
		0:
			master_label.text = percentage
		1:
			music_label.text = percentage
		2:
			effects_label.text = percentage
			
	Utility.set_config_value("audio", AudioServer.get_bus_name(index).to_lower() + "_volume", value)

func _on_ShowFPS_toggled(button_pressed):
	$"/root/FPSCounter".visible = button_pressed
	Utility.set_config_value("misc", "fps_counter", button_pressed)

# Update values 
func _on_OptionsMenu_visibility_changed():
	Global.log_normal("OptionsMenu: Visbility changed")
	$TabContainer/Visual/Fullscreen/Toggle.pressed = OS.window_fullscreen
	$TabContainer/Visual/Vsync/Toggle.pressed = OS.vsync_enabled
	$TabContainer/Misc/ShowFPS/Toggle.pressed = $"/root/FPSCounter".visible
	
	# Update volume slider values and labels
	master_slider.value = int(AudioServer.get_bus_volume_db(0))
	music_slider.value = int(AudioServer.get_bus_volume_db(1))
	effects_slider.value = int(AudioServer.get_bus_volume_db(2))
