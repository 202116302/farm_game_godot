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
@onready var csv_display_label = null

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
		
	csv_display_label = get_node_or_null("UI/CSVDisplay")
	if not csv_display_label:
		create_csv_display_label()
	
# CSV 표시용 Label 생성
func create_csv_display_label():
	csv_display_label = Label.new()
	csv_display_label.name = "CSVDisplay"
	csv_display_label.position = Vector2(10, 10)  # 화면 왼쪽 상단에 위치
	csv_display_label.size = Vector2(400, 300)
	csv_display_label.add_theme_color_override("font_color", Color.WHITE)
	csv_display_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	csv_display_label.add_theme_constant_override("shadow_offset_x", 1)
	csv_display_label.add_theme_constant_override("shadow_offset_y", 1)
	csv_display_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	csv_display_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# UI에 추가
	var ui_node = get_node("UI")
	if ui_node:
		ui_node.add_child(csv_display_label)
	else:
		add_child(csv_display_label)

# CSV 파일 로드 함수
func load_csv_from_desktop():
	# 바탕화면 경로 가져오기 (Windows 기준)
	var desktop_path = OS.get_environment("USERPROFILE") + "/Desktop/"
	
	# CSV 파일명 (실제 파일명으로 변경 필요)
	var csv_filename = "test.csv"  # 여기에 실제 CSV 파일명을 입력하세요
	var full_path = desktop_path + csv_filename
	
	print("CSV 파일 경로: ", full_path)
	
	# 파일 존재 확인
	if not FileAccess.file_exists(full_path):
		if csv_display_label:
			csv_display_label.text = "CSV 파일을 찾을 수 없습니다: " + csv_filename
		print("파일이 존재하지 않습니다: ", full_path)
		return
	
	# 파일 읽기
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		if csv_display_label:
			var error_code = FileAccess.get_open_error()
			var error_message = "파일 열기 실패 - 오류 코드: " + str(error_code)
			csv_display_label.text = error_message
		print("파일 열기 실패: ", FileAccess.get_open_error())
		return
	
	var csv_content = ""
	var line_count = 0
	var max_lines = 20  # 표시할 최대 라인 수
	
	# CSV 파일을 한 줄씩 읽어서 포맷팅
	while not file.eof_reached() and line_count < max_lines:
		var line = file.get_line()
		if line.strip_edges() != "":  # 빈 줄이 아닌 경우만
			# CSV를 테이블 형태로 표시하기 위해 탭으로 구분
			var formatted_line = line.replace(",", "  |  ")
			csv_content += formatted_line + "\n"
			line_count += 1
	
	file.close()
	
	# Label에 표시
	if csv_display_label:
		csv_display_label.text = "CSV 파일 내용 (" + csv_filename + "):\n\n" + csv_content
		if line_count >= max_lines:
			csv_display_label.text += "\n... (더 많은 데이터가 있습니다)"
	
	print("CSV 파일 로드 완료: ", line_count, "줄")

# 키 입력으로 CSV 로드 (기존 _input 함수에 추가)
func _input(event):
	# 기존 _input 코드...
	
	# C키를 누르면 CSV 로드
	if event.is_action_pressed("ui_cancel"):  # ESC 키 또는 원하는 키로 변경
		load_csv_from_desktop()

# CSV 표시/숨기기 토글
func toggle_csv_display():
	if csv_display_label:
		csv_display_label.visible = !csv_display_label.visible
		
		
		 
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
