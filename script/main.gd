extends Node

@export var playtime = 30

var level = 1
var score = 0
var time_left = 0 
var screensize = Vector2.ZERO
var playing = false 

@onready var rain_scene = preload("res://scene/Rain.tscn")
var rain_instance


func _ready():
	#screensize = get_viewport().get_visible_rect().size
	screensize = Vector2(get_window().size)
	if $Player.has_method("set_screensize"):  # 메서드를 통해 전달
		$Player.set_screensize(screensize)
		
	$barn_menu.hide()
	#$Player.screensize = screensize
	#$Player.hide()
	rain_instance = rain_scene.instantiate()
	add_child(rain_instance)
	
	if $UI/blank/Panel/Date.has_signal("day_changed"):
		$UI/blank/Panel/Date.day_changed.connect(_on_weather_change)
	
 
func _on_weather_change():
	var random_value = randf()
	print("Weather change check - Random value: ", random_value)  # 디버깅용
	
	if random_value < 0.5:
		print("Starting rain")  # 디버깅용
		rain_instance.start_rain()
		$UI/blank/Panel/Weather.text = "날씨: 비"
	else:
		print("Stopping rain")  # 디버깅용
		rain_instance.stop_rain()
		$UI/blank/Panel/Weather.text = "날씨: 맑음"
