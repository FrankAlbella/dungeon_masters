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
		
	Global.log_normal("Config file load successful")
