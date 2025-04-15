extends Node

@export var playtime = 30

var level = 1
var score = 0
var time_left = 0 
var screensize = Vector2.ZERO
var playing = false 

@onready var rain_scene = preload("res://scene/Rain.tscn")
@onready var background_tilemap = get_node("Background")

@onready var animal_scene = preload("res://scene/Animal.tscn")

var rain_instance


# 동물 스폰 함수
func spawn_animal(pos = null):
	var animal = animal_scene.instantiate()
	
	# 위치를 지정하지 않았다면 랜덤 위치 설정
	if pos == null:
		var rand_x = randf_range(100, screensize.x - 100)
		var rand_y = randf_range(100, screensize.y - 100)
		animal.position = Vector2(rand_x, rand_y)
	else:
		animal.position = pos
	
	add_child(animal)
	return animal
	

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
		
	for i in range(3):
		spawn_animal()
	
 
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
			0
			player.watered_dates[str(current_month) + "_" + str(current_day)] = true
			print(player.watered_dates)
			
			
		for tile_pos in player.planted_crops.keys():
			var lettuce = player.planted_crops[tile_pos]["instance"]
			if is_instance_valid(lettuce):
				lettuce.water()
				print("비로 인해 상추에 물 줌: ", tile_pos)
			
			
		
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
