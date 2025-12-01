extends Control

# 노드 참조
@onready var close_button = $weather_window/container/CloseButton
@onready var title_label = $weather_window/container/TitleLabel
@onready var container = $weather_window/container

# 기상 정보용 노드
@onready var weather_display = $weather_window/container/WeatherDisplay
@onready var graph_display = $weather_window/container/GraphDisplay
@onready var refresh_button = $weather_window/container/RefreshButton
@onready var graph_type_selector = $weather_window/container/GraphTypeSelector
@onready var http_request = $HTTPRequest
@onready var http_request_graph = $HTTPRequestGraph

# API 설정
var api_base = "http://34.229.121.126:8000"
var current_graph_type = "separate"

var is_popup_mode = false
var is_loading_weather = false
var is_loading_graph = false

func _ready():
	## 기본 설정
	setup_enhanced_ui()
	
	## 시그널 연결
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if graph_type_selector:
		graph_type_selector.item_selected.connect(_on_graph_type_selected)
	
	if http_request:
		http_request.request_completed.connect(_on_weather_request_completed)
	if http_request_graph:
		http_request_graph.request_completed.connect(_on_graph_request_completed)
	
	## 초기에는 숨김
	hide()
	z_index = 2 

func setup_enhanced_ui():
	# 기존 배경 스타일 유지
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.3, 0.95)
	style_box.border_color = Color(0.3, 0.3, 0.6, 1.0)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	add_theme_stylebox_override("panel", style_box)
	
	# 기상 정보 표시 설정
	if weather_display:
		weather_display.bbcode_enabled = true
		weather_display.text = "[center][color=gray]기상 데이터를 불러오는 중...[/color][/center]"
	
	# 그래프 선택기 설정
	if graph_type_selector:
		setup_graph_selector()
	
	# 제목 라벨 설정
	if title_label:
		title_label.text = "🌤️ 온실 환경 정보"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	# 레이아웃 설정
	layout_popup_elements()

func setup_graph_selector():
	graph_type_selector.clear()
	graph_type_selector.add_item("개별 그래프", 0)
	graph_type_selector.add_item("일별 그래프", 1)
	graph_type_selector.add_item("종합 그래프", 2)
	graph_type_selector.selected = 0

func layout_popup_elements():
	# 팝업 크기를 넓게 (그래프 표시를 위해)
	var popup_size = Vector2(900, 600)
	size = popup_size
	container.position = Vector2(100, 120)
	
	# 제목과 닫기 버튼 (기존 위치 유지)
	if title_label:
		title_label.position = Vector2(50, -20)
		title_label.size = Vector2(size.x - 100, 30)
	
	if close_button:
		close_button.position = Vector2(size.x - 80, -20)
		close_button.size = Vector2(60, 30)
		close_button.text = "✕"
	
	# 컨텐츠 영역
	var content_top = 20
	var content_height = size.y - content_top 
	
	# 새로고침 버튼과 그래프 선택
	if refresh_button:
		refresh_button.position = Vector2(20, content_top)
		refresh_button.size = Vector2(100, 30)
		refresh_button.text = "새로고침"
		refresh_button.show()
	
	if graph_type_selector:
		graph_type_selector.position = Vector2(130, content_top)
		graph_type_selector.size = Vector2(150, 30)
		graph_type_selector.show()
	
	# 좌우 분할: 기상 데이터(좌) | 그래프(우)
	var data_content_top = content_top + 40
	var data_content_height = content_height - 40
	var left_width = 280  # 기상 데이터 영역
	var right_width = size.x - left_width - 60  # 그래프 영역
	
	# 기상 데이터 표시 (좌측)
	if weather_display:
		weather_display.position = Vector2(20, data_content_top)
		weather_display.size = Vector2(left_width, data_content_height)
		weather_display.show()
	
	# 그래프 표시 (우측)
	if graph_display:
		graph_display.position = Vector2(left_width + 40, data_content_top)
		graph_display.size = Vector2(right_width, data_content_height)
		graph_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		graph_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		graph_display.show()

func show_popup():
	is_popup_mode = true
	layout_popup_elements()
	show()
	
	# 데이터 로드
	load_weather_data()
	print("스마트팜 기상 정보 팝업 표시됨")

func hide_popup():
	hide()
	print("스마트팜 기상 정보 팝업 숨김")

func _on_close_pressed():
	hide_popup()

func _on_refresh_pressed():
	load_weather_data()

func _on_graph_type_selected(index: int):
	match index:
		2:
			current_graph_type = "combined"
		0:
			current_graph_type = "separate"
		1:
			current_graph_type = "daily"
	
	# 그래프 다시 로드
	load_graph_image()

func load_weather_data():
	# 최신 기상 데이터 로드
	fetch_latest_weather()
	# 그래프 생성 후 이미지 로드
	generate_and_load_graph()

func fetch_latest_weather():
	if is_loading_weather:
		return
	
	is_loading_weather = true
	var api_url = api_base + "/api/weather/latest"
	
	if weather_display:
		weather_display.text = "[center][color=yellow]최신 기상 데이터 로딩 중...[/color][/center]"
	
	print("기상 데이터 API 요청: ", api_url)
	
	var error = http_request.request(api_url)
	if error != OK:
		is_loading_weather = false
		if weather_display:
			weather_display.text = "[color=red]API 요청 실패: " + str(error) + "[/color]"

func _on_weather_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_loading_weather = false
	
	print("기상 데이터 API 응답 코드: ", response_code)
	
	if response_code != 200:
		if weather_display:
			weather_display.text = "[color=red]서버 오류: " + str(response_code) + "[/color]"
		return
	
	var json_string = body.get_string_from_utf8()
	print("받은 기상 데이터: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		if weather_display:
			weather_display.text = "[color=red]데이터 파싱 오류[/color]"
		return
	
	var data = json.data
	display_weather_data(data)

func display_weather_data(data: Dictionary):
	if not weather_display:
		return
	
	var content = "[center][color=white]🌤️ 최신 기상 정보[/color][/center]\n\n"
	
	# 타임스탬프
	if data.has("timestamp"):
		var timestamp = data["timestamp"]
		content += "[color=lightblue]📅 측정 시간[/color]\n"
		content += "[color=white]" + str(timestamp) + "[/color]\n\n"
	
	# 온도
	if data.has("temp"):
		content += "[color=orange]🌡️ 온도[/color]\n"
		content += "[color=white]" + str(data["temp"]) + " °C[/color]\n\n"
	
	# 습도
	if data.has("humid"):
		content += "[color=cyan]💧 습도[/color]\n"
		content += "[color=white]" + str(data["humid"]) + " %[/color]\n\n"
	
	# 일사량
	if data.has("radn"):
		content += "[color=yellow]☀️ 일사량[/color]\n"
		content += "[color=white]" + str(data["radn"]) + " W/m²[/color]\n\n"
	
	# 풍속
	if data.has("wind"):
		content += "[color=lightgreen]💨 풍속[/color]\n"
		content += "[color=white]" + str(data["wind"]) + " m/s[/color]\n\n"
	
	# 풍향
	if data.has("wind_degree"):
		content += "[color=lightgreen]🧭 풍향[/color]\n"
		content += "[color=white]" + str(data["wind_degree"]) + " °[/color]\n\n"
	
	# 강우량
	if data.has("rainfall"):
		content += "[color=blue]🌧️ 강우량[/color]\n"
		content += "[color=white]" + str(data["rainfall"]) + " mm[/color]\n\n"
	
	# 배터리
	if data.has("battery"):
		content += "[color=gray]🔋 배터리[/color]\n"
		content += "[color=white]" + str(data["battery"]) + " V[/color]\n"
	
	weather_display.text = content

func generate_and_load_graph():
	# 먼저 그래프 생성 API 호출
	var generate_url = api_base + "/api/graph/generate"
	print("그래프 생성 요청: ", generate_url)
	
	# 간단히 바로 이미지 로드 (생성은 백그라운드에서)
	await get_tree().create_timer(0.5).timeout
	load_graph_image()

func load_graph_image():
	if is_loading_graph:
		return
	
	is_loading_graph = true
	var graph_url = api_base + "/api/graph/image/" + current_graph_type
	
	print("그래프 이미지 요청: ", graph_url)
	
	var error = http_request_graph.request(graph_url)
	if error != OK:
		is_loading_graph = false
		print("그래프 이미지 요청 실패: ", error)

func _on_graph_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_loading_graph = false
	
	print("그래프 이미지 응답 코드: ", response_code)
	
	if response_code != 200:
		print("그래프 이미지 로드 실패: ", response_code)
		return
	
	# 이미지 데이터를 텍스처로 변환
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	
	if error != OK:
		print("이미지 로드 실패: ", error)
		return
	
	var texture = ImageTexture.create_from_image(image)
	
	if graph_display:
		graph_display.texture = texture
		print("그래프 이미지 표시 완료")

func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):
		hide_popup()
