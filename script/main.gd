extends Node

@export var playtime = 30

var level = 1
var score = 0
var time_left = 0 
var screensize = Vector2.ZERO
var playing = false 

@onready var rain_scene = preload("res://scene/Rain.tscn")
@onready var background_tilemap = get_node("Background")
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
		update_field_tiles(5)
		
		var date_node = get_node("/root/Main/UI/blank/Panel/Date")
		var player = get_node("/root/Main/Player")
		if date_node:
			var current_day = date_node.get_day()
			var current_month = date_node.get_month()
			
			player.watered_dates[str(current_month) + "_" + str(current_day)] = true
			print(player.watered_dates)
		
	else:
		print("Stopping rain")  # 디버깅용
		rain_instance.stop_rain()
		$UI/blank/Panel/Weather.text = "날씨: 맑음"
		
		update_field_tiles(22)
		
		
func update_field_tiles(id):
	if not background_tilemap:
		print('z')
		return
		
	var used_cells = background_tilemap.get_used_cells()
	
	for cell in used_cells:
		var current_source_id = background_tilemap.get_cell_source_id(cell)
		if current_source_id == id:
			if id == 22:  # 물 준 타일
				background_tilemap.set_cell(cell, 5, Vector2i(0, 0)) 
			elif id == 5:
				background_tilemap.set_cell(cell, 22, Vector2i(0, 0))
