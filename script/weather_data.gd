extends Control

# 노드 참조
@onready var weather_display = $WeatherDisplay
@onready var refresh_button = $RefreshButton
@onready var http_request = $HTTPRequest
# 새로 추가될 노드들
@onready var region_selector = $RegionSelector
@onready var close_button = $CloseButton
@onready var title_label = $TitleLabel
# API 설정 (순창 지역 날씨)
#var api_url = "http://web01.taegon.kr:7500/weather_now/sunchang"
var regions = {
	"순창": "http://web01.taegon.kr:7500/weather_now/sunchang",
	"익산": "http://web01.taegon.kr:7500/weather_now/iksan", 
	"남원": "http://web01.taegon.kr:7500/weather_now/namwon",

	}
	
var current_region = "순창"
var is_popup_mode = false

	
	
func _ready():
	## 기본 설정
	setup_enhanced_ui()
	
	## 시그널 연결
	refresh_button.pressed.connect(_on_refresh_pressed)
	http_request.request_completed.connect(_on_request_completed)
	
	# 새로운 시그널 연결
	if region_selector:
		region_selector.item_selected.connect(_on_region_selected)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	## 초기에는 숨김
	hide()

func setup_enhanced_ui():
	# 기존 배경 스타일 유지하되 팝업용으로 개선
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.3, 0.95)  # 약간 더 불투명하게
	style_box.border_color = Color(0.3, 0.3, 0.6, 1.0)  # 테두리 추가
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	add_theme_stylebox_override("panel", style_box)
	
	# 날씨 표시 설정
	weather_display.bbcode_enabled = true
	weather_display.text = "[center][color=gray]날씨 정보 로딩 중...[/color][/center]"
	
	# 지역 선택기 설정
	if region_selector:
		setup_region_selector()
	
	# 제목 라벨 설정
	if title_label:
		title_label.text = "🌤️ 날씨 관측소"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 버튼들 위치 조정
	layout_popup_elements()

func setup_region_selector():
	region_selector.clear()
	for region_name in regions.keys():
		region_selector.add_item(region_name)
	
	# 기본값으로 순창 선택
	var sunchang_index = regions.keys().find("순창")
	if sunchang_index >= 0:
		region_selector.selected = sunchang_index

func layout_popup_elements():
	# 팝업 모드일 때의 레이아웃
	if is_popup_mode:
		# 화면 중앙에 배치
		var screen_size = get_viewport().get_visible_rect().size
		var popup_size = Vector2(500, 400)
		position = (screen_size - popup_size) / 2
		size = popup_size
		
		# 요소들 위치 조정
		if title_label:
			title_label.position = Vector2(10, 10)
			title_label.size = Vector2(size.x - 20, 30)
		
		if region_selector:
			region_selector.position = Vector2(20, 50)
			region_selector.size = Vector2(200, 30)
		
		if refresh_button:
			refresh_button.position = Vector2(240, 50)
			refresh_button.size = Vector2(100, 30)
			refresh_button.text = "새로고침"
		
		if close_button:
			close_button.position = Vector2(size.x - 80, 50)
			close_button.size = Vector2(60, 30)
			close_button.text = "✕"
		
		if weather_display:
			weather_display.position = Vector2(20, 90)
			weather_display.size = Vector2(size.x - 40, size.y - 110)

func show_popup():
	is_popup_mode = true
	layout_popup_elements()
	show()
	fetch_weather()
	print("날씨 팝업 표시됨")

func hide_popup():
	hide()
	print("날씨 팝업 숨김")

func _on_region_selected(index: int):
	var region_names = regions.keys()
	if index < region_names.size():
		current_region = region_names[index]
		fetch_weather()
		print("선택된 지역: ", current_region)

func _on_close_pressed():
	hide_popup()

func fetch_weather():
	var api_url = regions.get(current_region, regions["순창"])
	
	print(current_region + " 날씨 API 요청: ", api_url)
	
	# 로딩 메시지 표시
	weather_display.text = "[center][color=yellow]" + current_region + " 날씨 정보 로딩 중...[/color][/center]"
	
	var error = http_request.request(api_url)
	if error != OK:
		weather_display.text = "[color=red]요청 실패: " + str(error) + "[/color]"

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("API 응답 코드: ", response_code)
	
	if response_code != 200:
		weather_display.text = "[color=red]서버 오류: " + str(response_code) + "[/color]"
		return
	
	var json_string = body.get_string_from_utf8()
	print("받은 데이터: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		weather_display.text = "[color=red]데이터 파싱 오류[/color]"
		return
	
	var weather_data = json.data
	
	# 데이터 타입 확인
	if weather_data is Dictionary:
		display_weather(weather_data)
	elif weather_data is String:
		# String으로 받았다면 다시 JSON 파싱 시도
		var inner_json = JSON.new()
		var inner_parse = inner_json.parse(weather_data)
		if inner_parse == OK and inner_json.data is Dictionary:
			display_weather(inner_json.data)
		else:
			weather_display.text = "[color=red]데이터 형식 오류: String 데이터를 Dictionary로 변환할 수 없습니다[/color]"
	else:
		weather_display.text = "[color=red]예상하지 못한 데이터 타입: " + str(typeof(weather_data)) + "[/color]"

func display_weather(data: Dictionary):
	# 응답 데이터에서 필요한 정보 추출
	var now_time = data.get("now_time", "시간 정보 없음")
	var temperature = data.get("ta", "온도 정보 없음")
	var wind_speed = data.get("ws", "풍속 정보 없음")
	var wind_direction = data.get("wdKo", "풍향 정보 없음")
	var weather_korean = data.get("wwKo", "날씨 정보 없음")
	var humidity = data.get("hm", "")
	var pressure = data.get("pa", "")
	var update_log = data.get("log", "")
	
	# 날씨 아이콘 선택
	var weather_icon = get_weather_icon_korean(weather_korean)
	
	var content = "[center][b][color=lightblue]" + weather_icon + " " + current_region + " 날씨[/color][/b][/center]\n\n"
	content += "[color=white]📍 지역:     [/color][color=yellow]" + current_region + "[/color]\n"
	content += "[color=white]🌡️ 온도:     [/color][color=yellow]" + str(temperature) + "°C[/color]\n"
	content += "[color=white]💨 풍속:     [/color][color=cyan]" + str(wind_speed) + " m/s[/color]\n"
	content += "[color=white]🧭 풍향:     [/color][color=lightgreen]" + str(wind_direction) + "[/color]\n"
	content += "[color=white]☁️ 날씨:     [/color][color=white]" + str(weather_korean) + "[/color]\n"
	
	# 추가 정보가 있으면 표시
	if humidity != "":
		content += "[color=white]💧 습도:     [/color][color=lightblue]" + str(humidity) + "%[/color]\n"
	if pressure != "":
		content += "[color=white]📊 기압:     [/color][color=pink]" + str(pressure) + " hPa[/color]\n"
	
	content += "\n[color=gray]📅 " + str(now_time) + "[/color]\n"
	
	if update_log != "":
		content += "[color=gray]" + update_log + "[/color]"
	
	weather_display.text = content
	print(current_region + " 날씨 데이터 표시 완료")

func get_weather_icon_korean(weather_desc: String) -> String:
	var desc_str = str(weather_desc).to_lower()
	
	if "맑" in desc_str:
		return "☀️"
	elif "구름조금" in desc_str or "구름적음" in desc_str:
		return "🌤️"
	elif "구름많음" in desc_str or "흐림" in desc_str:
		return "☁️"
	elif "비" in desc_str or "소나기" in desc_str:
		return "🌧️"
	elif "눈" in desc_str:
		return "🌨️"
	elif "안개" in desc_str or "박무" in desc_str:
		return "🌫️"
	elif "천둥" in desc_str or "번개" in desc_str:
		return "⛈️"
	else:
		return "🌤️"

func _on_refresh_pressed():
	fetch_weather()

# ESC 키로 팝업 닫기
func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):  # ESC
		hide_popup()

# 위치 설정 (기존 함수 유지 - 호환성)
func set_position_simple(x: float, y: float, width: float, height: float):
	if not is_popup_mode:
		position = Vector2(x, y)
		size = Vector2(width, height)
