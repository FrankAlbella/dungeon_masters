extends Node

signal log_message(msg)

const MENU_SCENE_PATH = "res://scenes/menus/3DMenu.tscn"
const USER_OPTIONS_FILE = "user://options.cfg"

const MAIN_SCENE_PATH = "res://scenes/stages/test_stage.tscn"

const PAUSE_MENU_SCENE = preload("res://scenes/menus/PauseMenu.tscn")
var pause_scene = null

var stage_list = {
	"3D Platformer": "res://scenes/stages/stage.scn",
	"Test Stage": "res://scenes/stages/test_stage.tscn"
}

var canvas_layer = null

var current_scene = null
var is_multiplayer = false

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
func _unhandled_key_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("toggle_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		if Input.is_action_pressed("ui_cancel") and not current_scene is MainMenu:
			toggle_pause()
		
		
func toggle_pause():
	if pause_scene == null:
		pause_scene = PAUSE_MENU_SCENE.instance()
		
		canvas_layer.add_child(pause_scene)
		
	pause_scene.toggle_pause()
	
func get_current_scene():
	return current_scene
	
func free_current_scene() -> void:
	call_deferred("_deffered_free_current_scene")
	
func set_current_scene(node) -> void:
	call_deferred("_deffered_set_current_scene", node)

func _deffered_set_current_scene(node) -> void:
	if not current_scene == null:
		current_scene.free()
	
	current_scene = node
	
func _deffered_free_current_scene() -> void:
	if not current_scene == null:
		current_scene.free()
	current_scene = null
	
# TODO: Add return type
func load_scene(path: String):
	if not current_scene == null:
		current_scene.free()
		
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	return s

func goto_scene(path: String) -> void:
	call_deferred("_deferred_goto_scene", path)
	
func _deferred_goto_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("ERROR: Could not change scene! " + path + " does not exist!")
		return
	
	log_normal("Changing scene to: " + path)
	
	if not pause_scene == null and pause_scene.visible:
		pause_scene.unpause()
	
	current_scene.free()
	
	var s = ResourceLoader.load(path)
	
	current_scene = s.instance()
	
	get_tree().get_root().add_child(current_scene)
	
	get_tree().set_current_scene(current_scene)
	
func log_normal(msg: String, emit := false) -> void:
	var message = "LOG: " + msg
	print(message)
	
	if emit:
		emit_signal("log_message", message)

func log_warning(msg: String, emit := false) -> void:
	var message = "WARNING: " + msg
	print("WARNING: " + msg)
	
	if emit:
		emit_signal("log_message", message)

func log_error(msg: String, emit := false) -> void:
	var message = "ERROR: " + msg
	print("ERROR: " + msg)
	
	if emit:
		emit_signal("log_message", message)
