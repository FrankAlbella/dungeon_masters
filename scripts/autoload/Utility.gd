extends Node

var _config_file = ConfigFile.new()

func _ready():
	load_config()

func get_config_file() -> ConfigFile:
	return _config_file

func save_config_to_file() -> void:
	Global.log_normal("Saving config file")
	var result = _config_file.save(Global.USER_OPTIONS_FILE)
	
	if result != OK:
		Global.log_error("Config file save failed: " + str(result))
	
func set_config_value(section: String, key: String, value) -> void:
	_config_file.set_value(section, key, value)
	save_config_to_file()
	
func get_config_value(section: String, key: String, default=null):
	if not _config_file.has_section_key(section, key):
		Global.log_normal("ConfigFile: \'" + section + ", " + key + "\' not found")
		return default
		
	return _config_file.get_value(section, key)

func load_config() -> void:
	# Create the config if it does not exist
	if not File.new().file_exists(Global.USER_OPTIONS_FILE):
		save_config_to_file()
		
	var result = _config_file.load(Global.USER_OPTIONS_FILE)
	
	if result != OK:
		Global.log_error("Config file load failed: " + str(result))
		return
	
	# Apply settings from config file
	
	# VISUAL
	OS.window_fullscreen = get_config_value("visual", "fullscreen", true)
	OS.vsync_enabled = get_config_value("visual", "vsync", true)
	
	# AUDIO
	change_volume(float(Utility.get_config_value("audio", "master_volume", 0.0)), Global.MASTER_AUDIO_BUS_INDEX, false)
	change_volume(float(Utility.get_config_value("audio", "music_volume", 0.0)), Global.MUSIC_AUDIO_BUS_INDEX, false)
	change_volume(float(Utility.get_config_value("audio", "effects_volume", 0.0)), Global.EFFECT_AUDIO_BUS_INDEX, false)
	
	# MISC
	$"/root/FPSCounter".visible = Utility.get_config_value("misc", "fps_counter", true)
	
	Global.log_normal("Config file load successful")
	
func change_volume(value, index, save_to_file = true):
	AudioServer.set_bus_volume_db(index, value)
	
	if value == Global.MIN_VOLUME_DB:
		AudioServer.set_bus_mute(index, true)
	elif AudioServer.is_bus_mute(index):
		AudioServer.set_bus_mute(index, false)
		
	if save_to_file:
		set_config_value("audio", AudioServer.get_bus_name(index).to_lower() + "_volume", value)
