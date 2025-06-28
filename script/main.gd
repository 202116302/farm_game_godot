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
@onready var farmkit = $farmkit
@onready var weather_data = $WeatherData
@onready var weather_station = $WeatherStation

var rain_instance
#var weather_data_scene = preload("res://scene/weather_data.tscn")
#var weather_data_instance = null


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
	
	#if $UI/blank/Panel/Date.has_signal("day_changed"):
		#$UI/blank/Panel/Date.day_changed.connect(_on_weather_change)
		
	for i in range(3):
		spawn_animal()
	
	setup_farmkit()
	#setup_simple_weather()
	setup_weather_system()
func setup_weather_system():
	# WeatherData를 팝업 모드로 설정 (초기에는 숨김)
	if weather_data:
		weather_data.hide()
		print("WeatherData 팝업 모드로 설정됨")
	
	# WeatherStation 설정
	setup_weather_station()

func setup_weather_station():
	# WeatherStation 노드가 존재하는지 확인
	if not weather_station:
		print("WeatherStation 노드를 찾을 수 없습니다!")
		return
	
	# 날씨 관측소 위치 설정 (원하는 위치로 조정 가능)
	weather_station.position = Vector2(200, 200)
	
	print("날씨 관측소 설정 완료 - 위치: ", weather_station.position)


		
		 
#func _on_weather_change():
	#var random_value = randf()
	#print("Weather change check - Random value: ", random_value)  # 디버깅용
	#
	#if random_value < 0.5:
		#print("Starting rain")  # 디버깅용
		#rain_instance.start_rain()
		#$UI/blank/Panel/Weather.text = "날씨: 비"
		#update_field_tiles(5)
		#
		#var date_node = get_node("/root/Main/UI/blank/Panel/Date")
		#var player = get_node("/root/Main/Player")
		#if date_node:
			#var current_day = date_node.get_day()
			#var current_month = date_node.get_month()
			#0
			#player.watered_dates[str(current_month) + "_" + str(current_day)] = true
			#print(player.watered_dates)
			#
			#
		#for tile_pos in player.planted_crops.keys():
			#var lettuce = player.planted_crops[tile_pos]["instance"]
			#if is_instance_valid(lettuce):
				#lettuce.water()
				#print("비로 인해 상추에 물 줌: ", tile_pos)
			#
			#
		#
	#else:
		#print("Stopping rain")  # 디버깅용
		#rain_instance.stop_rain()
		#$UI/blank/Panel/Weather.text = "날씨: 맑음"
		#
		#update_field_tiles(22)
		#
		
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
				
				
				
func setup_farmkit():
	# farmkit 노드 존재 확인
	if not farmkit:
		print("farmkit 노드를 찾을 수 없습니다!")
		return
	
	# farmkit이 올바른 타입인지 확인
	if not is_instance_valid(farmkit):
		print("farmkit 노드가 유효하지 않습니다!")
		return
	
	# position_in_circle 메서드 존재 확인
	if not farmkit.has_method("position_in_circle"):
		print("farmkit에 position_in_circle 메서드가 없습니다!")
		# 대안: 직접 위치 설정
		farmkit.position = Vector2(-500, -850)
		farmkit.size = Vector2(380, 280)
	else:
		# 파란 원 위치에 farmkit 배치
		farmkit.position_in_circle(-500, -850, 380, 280)
		
		# farmkit 시그널 연결
		farmkit.farmkit_minimized.connect(_on_farmkit_minimized)
		farmkit.data_updated.connect(_on_farmkit_data_updated)
		
		print("farmkit 설정 완료")

# farmkit 시그널 핸들러
func _on_farmkit_minimized():
	print("farmkit이 최소화/복원되었습니다")

func _on_farmkit_data_updated(type: String, content):
	print("farmkit 데이터 업데이트: ", type)
	# 필요시 메인 게임에서 데이터 활용



func toggle_farmkit():
	if farmkit:
		if farmkit.visible:
			farmkit.hide_farmkit()
		else:
			farmkit.show_farmkit()

# farmkit에 특정 파일 로드
func load_farm_data(csv_filename: String = "test.csv", image_filepath: String = ""):
	if farmkit:
		if csv_filename != "":
			farmkit.load_specific_csv(csv_filename)
		if image_filepath != "":
			farmkit.load_specific_image(image_filepath)

# 바탕화면의 data.csv 직접 로드
func load_data_csv():
	if farmkit:
		farmkit.load_specific_csv("test.csv")
		
		
#func setup_simple_weather():
	#if weather_data:
		#weather_data.set_position_simple(100, -850, 400, 300)  # 위치만 설정
		#print("weather_data 설정 완료")
	#
	#print("간단한 날씨 위젯 설정 완료")
#
#func toggle_simple_weather():
	#if weather_data:
		#weather_data.visible = !weather_data.visible
		
		
		# 키보드 입력으로 farmkit 제어
func _input(event):
	# 기존 _input 코드...
	
	# F키로 farmkit 표시/숨기기
	if event.is_action_pressed("ui_cancel"):  # ESC 키
		toggle_farmkit()
	
	# R키로 farmkit 새로고침
	elif Input.is_action_just_pressed("ui_accept"):  # Enter 키
		if farmkit:
			farmkit._on_refresh_pressed()
			
