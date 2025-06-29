extends Control

# 노드 참조
@onready var region_selector = $weather_window/container/RegionSelector
@onready var weather_display = $weather_window/container/WeatherDisplay
@onready var forecast_display = $weather_window/container/ForecastDisplay  # 🆕 새로 추가!
@onready var refresh_button = $weather_window/container/RefreshButton
@onready var close_button = $weather_window/container/CloseButton
@onready var http_request = $HTTPRequest
@onready var title_label = $weather_window/container/TitleLabel
@onready var container = $weather_window/container

# 지역별 API URL 데이터 (현재 날씨 + 예보)
var regions = {
	"순창": {
		"current": "http://web01.taegon.kr:7500/weather_now/sunchang",
		"forecast": "http://web01.taegon.kr:7500/weather_short/sunchang"
	},
	"익산": {
		"current": "http://web01.taegon.kr:7500/weather_now/iksan",
		"forecast": "http://web01.taegon.kr:7500/weather_short/iksan"
	},
	"남원": {
		"current": "http://web01.taegon.kr:7500/weather_now/namwon",
		"forecast": "http://web01.taegon.kr:7500/weather_short/namwon"
	}
}

var current_region = "순창"
var is_popup_mode = false

# API 로딩 상태 관리
var is_loading_current = false
var is_loading_forecast = false

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
	z_index = 2 

func setup_enhanced_ui():
	# 기존 배경 스타일 유지하되 팝업용으로 개선
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
	
	# 날씨 표시 설정
	weather_display.bbcode_enabled = true
	weather_display.text = "[center][color=gray]현재 날씨 로딩 중...[/color][/center]"
	
	# 예보 표시 설정 (새로 추가!)
	if forecast_display:
		forecast_display.bbcode_enabled = true
		forecast_display.text = "[center][color=gray]예보 정보 로딩 중...[/color][/center]"
	
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
		# 화면 중앙에 배치 (예보 때문에 더 크게)
		var screen_size = get_viewport().get_visible_rect().size
		var popup_size = Vector2(600, 450)  # 더 크게!
		size = popup_size
		container.position = Vector2(40, 90)
		
		# 요소들 위치 조정
		if title_label:
			title_label.position = Vector2(10, -20)
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
		
		# 좌우 분할 레이아웃
		var content_top = 90
		var content_height = size.y - content_top - 20
		var content_width = (size.x - 60) / 2  # 좌우 분할
		
		# 현재 날씨 (좌측)
		if weather_display:
			weather_display.position = Vector2(20, content_top)
			weather_display.size = Vector2(content_width, content_height)
		
		# 예보 정보 (우측) - 새로 추가!
		if forecast_display:
			forecast_display.position = Vector2(30 + content_width, content_top)
			forecast_display.size = Vector2(content_width, content_height)

func show_popup():
	is_popup_mode = true
	layout_popup_elements()
	show()
	
	# 현재 날씨와 예보 모두 로드
	load_all_weather_data()
	print("날씨 팝업 표시됨")

func load_all_weather_data():
	# 현재 날씨 먼저 로드
	fetch_current_weather()

func hide_popup():
	hide()
	print("날씨 팝업 숨김")

func _on_region_selected(index: int):
	var region_names = regions.keys()
	if index < region_names.size():
		current_region = region_names[index]
		load_all_weather_data()  # 모든 데이터 다시 로드
		print("선택된 지역: ", current_region)

func _on_close_pressed():
	hide_popup()

# 현재 날씨 API 호출
func fetch_current_weather():
	if not regions.has(current_region):
		weather_display.text = "[color=red]지원하지 않는 지역입니다[/color]"
		return
	
	var api_url = regions[current_region]["current"]
	is_loading_current = true
	
	print(current_region + " 현재 날씨 API 요청: ", api_url)
	weather_display.text = "[center][color=yellow]" + current_region + " 현재 날씨 로딩 중...[/color][/center]"
	
	var error = http_request.request(api_url)
	if error != OK:
		weather_display.text = "[color=red]현재 날씨 요청 실패: " + str(error) + "[/color]"
		is_loading_current = false

# 예보 API 호출
func fetch_forecast_weather():
	if not regions.has(current_region):
		if forecast_display:
			forecast_display.text = "[color=red]지원하지 않는 지역입니다[/color]"
		return
	
	var api_url = regions[current_region]["forecast"]
	is_loading_forecast = true
	
	print(current_region + " 예보 API 요청: ", api_url)
	if forecast_display:
		forecast_display.text = "[center][color=yellow]" + current_region + " 예보 로딩 중...[/color][/center]"
	
	var error = http_request.request(api_url)
	if error != OK:
		if forecast_display:
			forecast_display.text = "[color=red]예보 요청 실패: " + str(error) + "[/color]"
		is_loading_forecast = false

# 통합된 fetch_weather (호환성)
func fetch_weather():
	load_all_weather_data()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("API 응답 코드: ", response_code)
	
	if response_code != 200:
		if is_loading_current:
			weather_display.text = "[color=red]현재 날씨 서버 오류: " + str(response_code) + "[/color]"
			is_loading_current = false
		elif is_loading_forecast:
			if forecast_display:
				forecast_display.text = "[color=red]예보 서버 오류: " + str(response_code) + "[/color]"
			is_loading_forecast = false
		return
	
	var json_string = body.get_string_from_utf8()
	print("받은 데이터: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		if is_loading_current:
			weather_display.text = "[color=red]현재 날씨 데이터 파싱 오류[/color]"
			is_loading_current = false
		elif is_loading_forecast:
			if forecast_display:
				forecast_display.text = "[color=red]예보 데이터 파싱 오류[/color]"
			is_loading_forecast = false
		return
	
	var data = json.data
	
	# 현재 날씨 또는 예보 데이터 처리
	if is_loading_current:
		handle_current_weather_response(data)
	elif is_loading_forecast:
		handle_forecast_response(data)

func handle_current_weather_response(data):
	is_loading_current = false
	
	if data is Dictionary:
		display_weather(data)
	elif data is String:
		var inner_json = JSON.new()
		var inner_parse = inner_json.parse(data)
		if inner_parse == OK and inner_json.data is Dictionary:
			display_weather(inner_json.data)
		else:
			weather_display.text = "[color=red]현재 날씨 데이터 형식 오류[/color]"
	
	# 현재 날씨 완료 후 예보 로드
	fetch_forecast_weather()

func handle_forecast_response(data):
	is_loading_forecast = false
	
	if data is String:
		var inner_json = JSON.new()
		var inner_parse = inner_json.parse(data)
		if inner_parse == OK and inner_json.data is Array:
			display_forecast_weather(inner_json.data)
		else:
			if forecast_display:
				forecast_display.text = "[color=red]예보 데이터 파싱 실패[/color]"
	elif data is Array:
		display_forecast_weather(data)
	else:
		if forecast_display:
			forecast_display.text = "[color=red]예보 데이터 형식 오류[/color]"

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
	
	var content = "[center][color=black]" + weather_icon + " " + current_region + " 현재 날씨[/color][/center]\n\n"
	content += "[color=black]📍 지역:     [/color][color=black]" + current_region + "[/color]\n"
	content += "[color=black]🌡️ 온도:     [/color][color=black]" + str(temperature) + "[/color]\n"
	content += "[color=black]💨 풍속:     [/color][color=black]" + str(wind_speed) + " [/color]\n"
	content += "[color=black]🧭 풍향:     [/color][color=black]" + str(wind_direction) + "[/color]\n"
	content += "[color=black]☁️ 날씨:     [/color][color=black]" + str(weather_korean) + "[/color]\n"
	
	# 추가 정보가 있으면 표시
	if humidity != "":
		content += "[color=black]💧 습도:     [/color][color=black]" + str(humidity) + "%[/color]\n"
	if pressure != "":
		content += "[color=black]📊 기압:     [/color][color=black]" + str(pressure) + " hPa[/color]\n"
	
	#content += "\n[color=black]📅 " + str(now_time) + "[/color]\n"
	
	if update_log != "":
		content += "[color=black]📅" + update_log + "[/color]"
	
	weather_display.text = content
	print(current_region + " 현재 날씨 데이터 표시 완료")

# 새로 추가: 예보 데이터 표시
func display_forecast_weather(forecast_data: Array):
	if not forecast_display:
		return
		
	if forecast_data.size() < 8:
		forecast_display.text = "[color=red]예보 데이터가 불완전합니다[/color]"
		return
	
	var dates = forecast_data[0]  # ["20250629", "20250630", ...]
	var display_dates = forecast_data[2]  # ["6/29 (일)", "6/30 (월)", ...]
	var rain_prob = forecast_data[3]  # 강수확률
	var humidity = forecast_data[4]  # 습도
	var weather_codes = forecast_data[5]  # 날씨 코드
	var min_temps = forecast_data[6] if forecast_data.size() > 6 else {}  # 최저기온
	var max_temps = forecast_data[7] if forecast_data.size() > 7 else {}  # 최고기온
	
	var content = "[center][color=black]🔮 단기 예보[/color][/center]\n\n"
	
	for i in range(1, min(dates.size(), 5)):  # 최대 5기일
		var date = dates[i]
		var display_date = display_dates[i] if i < display_dates.size() else date
		
		# 날씨 아이콘 (코드 기반)
		var weather_code = weather_codes.get(date, "1")
		var weather_icon = get_weather_icon_by_code(weather_code)
		
		# 기온 정보
		var temp_info = ""
		if max_temps.has(date) and min_temps.has(date):
			temp_info = str(max_temps[date]) + "/" + str(min_temps[date])
		elif max_temps.has(date):
			temp_info = "최고 " + str(max_temps[date])
		elif min_temps.has(date):
			temp_info = "최저 " + str(min_temps[date])
		
		# 강수확률
		var rain_info = rain_prob.get(date, "0%")
		
		content += "[color=black]" + weather_icon + " " + display_date + "[/color]\n"
		if temp_info != "":
			content += "   [color=black]🌡️ " + temp_info + "[/color]\n"
		content += "   [color=black]💧 " + rain_info + "[/color]\n\n"
	
	forecast_display.text = content
	print(current_region + " 예보 데이터 표시 완료")

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

# 새로 추가: 날씨 코드별 아이콘
func get_weather_icon_by_code(code: String) -> String:
	match code:
		"1":
			return "☀️"  # 맑음
		"2":
			return "🌤️"  # 구름조금
		"3":
			return "🌥️"  # 구름많음
		"4":
			return "☁️"  # 흐림
		"5", "6", "7":
			return "🌧️"  # 비
		"8", "9", "10":
			return "🌨️"  # 눈
		_:
			return "🌤️"  # 기본값

func _on_refresh_pressed():
	load_all_weather_data()  # 모든 데이터 새로고침

# ESC 키로 팝업 닫기
func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):  # ESC
		hide()
