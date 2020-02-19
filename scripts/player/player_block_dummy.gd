extends Spatial

export(bool) var unique_color = true
export(bool) var randomize_color = true

onready var _player_mesh = $player/Armature/Skeleton/Body

func _ready():
	if unique_color:
		_player_mesh.material_override = (_player_mesh.material_override.duplicate(true))
	
	if randomize_color:
		$Timer.start()


func randomize_color() -> void:
	#Global.log_normal("player_block: randomize_color()")
	var temp_color = Color(1,1,1,1)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var r = rng.randf_range(0,1)
	var g = rng.randf_range(0,1)
	var b = rng.randf_range(0,1)
	
	temp_color = Color(r, g, b, 1)
	
	set_color(temp_color)


remotesync func set_color(color: Color) -> void:
	#Global.log_normal("player_block: set_color()")
	_player_mesh.material_override.albedo_color = color


func _on_Timer_timeout() -> void:
	randomize_color()
