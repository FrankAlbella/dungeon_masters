extends Control

export(StreamTexture) var _portrait
export(float) var _max_health
export(float) var _max_mana  

export(float) var animate_time = 0.1

onready var life_bar = $life_bar_frame/life_bar
onready var mana_bar = $mana_bar_frame/mana_bar

func _ready():
	if _portrait != null:
		set_portrait(_portrait)
	
	if _max_health != null:
		set_max_health(_max_health)
		
	if _max_mana != null:
		set_max_mana(_max_mana)
	
func set_portrait(new_portrait: StreamTexture) -> void:
	Global.log_normal("set_portrait")
	if $portrait_frame/player_portrait != null:
		$portrait_frame/player_portrait.texture = new_portrait
		
func get_portrait() -> StreamTexture:
	return _portrait

func set_health(health: float) -> void:
	if $Tween != null and life_bar != null:
		$Tween.interpolate_property(life_bar, "value", life_bar.value, health, animate_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()

func set_mana(mana: float) -> void:
	if $Tween != null and mana_bar != null:
		$Tween.interpolate_property(mana_bar, "value", mana_bar.value, mana, animate_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()

func set_max_health(new_max_health: float) -> void:
	_max_health = new_max_health
	if life_bar != null:
		life_bar.max_value = _max_health

func set_max_mana(new_max_mana: float) -> void:
	_max_mana = new_max_mana
	if mana_bar != null:
		mana_bar.max_value = _max_mana

func get_max_health() -> float:
	return _max_health

func get_max_mana() -> float:
	return _max_mana
