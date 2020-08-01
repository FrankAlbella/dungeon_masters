tool
extends Sprite3D

export(Texture) var spritesheet setget _set_spritesheet, _get_spritesheet
export(int) var frame_width = 0
export(int) var frame_height = 0

func _ready():
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if spritesheet != null and frame_width != 0 and frame_height != 0:
		process_sprite()
	
func process_sprite():
	if not Engine.editor_hint and visible:
		var dir = global_transform.basis.z
		var pos = global_transform.origin
		var plyrPos = get_viewport().get_camera().get_global_transform().origin
		var a = Vector2(dir.x, dir.z) # Direction Sprite is looking
		var dir2Plyr = Vector2(plyrPos.x - pos.x, plyrPos.z - pos.z)
		
		var angle = a.angle_to(dir2Plyr)
		angle = rad2deg(angle) - 22.5
		if(angle < 0):
			angle += 360
			
		var xcord = frame_width * int(angle/45)
		region_rect = Rect2(xcord, 0, frame_width, frame_height)
	
func _set_spritesheet(new_sheet):
	spritesheet = new_sheet
	texture = spritesheet
	
func _get_spritesheet():
	return spritesheet
