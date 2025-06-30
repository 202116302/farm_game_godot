extends Control

# 기존 노드 참조
@onready var region_selector = $weather_window/container/RegionSelector
@onready var weather_display = $weather_window/container/WeatherDisplay
@onready var forecast_display = $weather_window/container/ForecastDisplay
@onready var refresh_button = $weather_window/container/RefreshButton
@onready var close_button = $weather_window/container/CloseButton
@onready var http_request = $HTTPRequest
@onready var title_label = $weather_window/container/TitleLabel
@onready var container = $weather_window/container

# 새로 추가할 노드 참조 (재배 조언용)
@onready var tab_weather = $weather_window/container/TabWeather
@onready var tab_cultivation = $weather_window/container/TabCultivation
@onready var crop_selector = $weather_window/container/CropSelector
@onready var chat_display = $weather_window/container/ChatDisplay
@onready var chat_input = $weather_window/container/ChatInput
@onready var send_button = $weather_window/container/SendButton
@onready var http_request_cultivation = $HTTPRequestCultivation

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

# 재배 조언 API 설정
var cultivation_api_base = "http://web01.taegon.kr:8000"
var crops = {
	"토마토": "tomato",
	"상추": "lettuce"
}

var current_region = "순창"
var current_crop = "토마토"
var current_tab = "weather"  # "weather" 또는 "cultivation"
var is_popup_mode = false

# API 로딩 상태 관리
var is_loading_current = false
var is_loading_forecast = false
var is_loading_cultivation = false

# 채팅 기록
var chat_history = []

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
	
	# 재배 조언 관련 시그널 연결
	if crop_selector:
		crop_selector.item_selected.connect(_on_crop_selected)
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_input_submitted)
	if http_request_cultivation:
		http_request_cultivation.request_completed.connect(_on_cultivation_request_completed)
	
	# 탭 버튼 시그널 연결
	if tab_weather:
		tab_weather.pressed.connect(_on_tab_weather_pressed)
	if tab_cultivation:
		tab_cultivation.pressed.connect(_on_tab_cultivation_pressed)
	
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
	
	# 예보 표시 설정
	if forecast_display:
		forecast_display.bbcode_enabled = true
		forecast_display.text = "[center][color=gray]예보 정보 로딩 중...[/color][/center]"
	
	# 지역 선택기 설정
	if region_selector:
		setup_region_selector()
	
	# 작물 선택기 설정
	if crop_selector:
		setup_crop_selector()
	
	# 채팅 표시 설정
	if chat_display:
		chat_display.bbcode_enabled = true
		chat_display.text = "[center][color=gray]재배 조언을 위해 질문을 입력해주세요![/color][/center]"
	
	# 채팅 입력창 설정
	if chat_input:
		chat_input.placeholder_text = "예: 토마토 물주기 주기는 어떻게 되나요?"
	
	# 제목 라벨 설정
	if title_label:
		title_label.text = "🌤️ 스마트 농업 도우미"
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

func setup_crop_selector():
	crop_selector.clear()
	for crop_name in crops.keys():
		crop_selector.add_item(crop_name)
	
	# 기본값으로 토마토 선택
	crop_selector.selected = 0

func layout_popup_elements():
	# 팝업 모드일 때의 레이아웃
	if is_popup_mode:
		# 화면 중앙에 배치 (탭 시스템으로 더 크게)
		var screen_size = get_viewport().get_visible_rect().size
		var popup_size = Vector2(700, 500)  # 더 크게!
		size = popup_size
		container.position = Vector2(60, 120)
		
		# 제목과 닫기 버튼
		if title_label:
			title_label.position = Vector2(10, -20)
			title_label.size = Vector2(size.x - 100, 30)
		
		if close_button:
			close_button.position = Vector2(size.x - 80, -20)
			close_button.size = Vector2(60, 30)
			close_button.text = "✕"
		
		# 탭 버튼들
		if tab_weather:
			tab_weather.position = Vector2(20, 20)
			tab_weather.size = Vector2(100, 30)
			tab_weather.text = "🌤️ 날씨"
		
		if tab_cultivation:
			tab_cultivation.position = Vector2(130, 20)
			tab_cultivation.size = Vector2(120, 30)
			tab_cultivation.text = "🌱 재배조언"
		
		# 컨텐츠 영역
		var content_top = 60
		var content_height = size.y - content_top - 20
		
		if current_tab == "weather":
			layout_weather_tab(content_top, content_height)
		else:
			layout_cultivation_tab(content_top, content_height)

func layout_weather_tab(content_top: int, content_height: int):
	# 날씨 탭 레이아웃
	
	# 지역 선택과 새로고침 버튼
	if region_selector:
		region_selector.position = Vector2(20, content_top)
		region_selector.size = Vector2(200, 30)
		region_selector.show()
	
	if refresh_button:
		refresh_button.position = Vector2(240, content_top)
		refresh_button.size = Vector2(100, 30)
		refresh_button.text = "새로고침"
		refresh_button.show()
	
	# 좌우 분할 레이아웃 (현재 날씨 | 예보)
	var weather_content_top = content_top + 40
	var weather_content_height = content_height - 40
	var content_width = (size.x - 60) / 2
	
	# 현재 날씨 (좌측)
	if weather_display:
		weather_display.position = Vector2(20, weather_content_top)
		weather_display.size = Vector2(content_width, weather_content_height)
		weather_display.show()
	
	# 예보 정보 (우측)
	if forecast_display:
		forecast_display.position = Vector2(30 + content_width, weather_content_top)
		forecast_display.size = Vector2(content_width, weather_content_height)
		forecast_display.show()
	
	# 재배 조언 요소들 숨기기
	hide_cultivation_elements()

func layout_cultivation_tab(content_top: int, content_height: int):
	# 재배 조언 탭 레이아웃
	
	# 작물 선택
	if crop_selector:
		crop_selector.position = Vector2(20, content_top)
		crop_selector.size = Vector2(200, 30)
		crop_selector.show()
	
	# 채팅 표시 영역
	if chat_display:
		chat_display.position = Vector2(20, content_top + 40)
		chat_display.size = Vector2(size.x - 80, content_height - 80)
		chat_display.show()
	
	# 입력창과 전송 버튼
	if chat_input:
		chat_input.position = Vector2(20, content_top + content_height - 30)
		chat_input.size = Vector2(size.x - 160, 30)
		chat_input.show()
	
	if send_button:
		send_button.position = Vector2(size.x - 120, content_top + content_height - 30)
		send_button.size = Vector2(80, 30)
		send_button.text = "전송"
		send_button.show()
	
	# 날씨 요소들 숨기기
	hide_weather_elements()

func hide_weather_elements():
	if region_selector:
		region_selector.hide()
	if refresh_button:
		refresh_button.hide()
	if weather_display:
		weather_display.hide()
	if forecast_display:
		forecast_display.hide()

func hide_cultivation_elements():
	if crop_selector:
		crop_selector.hide()
	if chat_display:
		chat_display.hide()
	if chat_input:
		chat_input.hide()
	if send_button:
		send_button.hide()

func show_popup():
	is_popup_mode = true
	current_tab = "weather"  # 기본적으로 날씨 탭 표시
	layout_popup_elements()
	show()
	
	# 현재 날씨와 예보 모두 로드
	load_all_weather_data()
	print("스마트 농업 도우미 팝업 표시됨")

func load_all_weather_data():
	# 현재 날씨 먼저 로드
	fetch_current_weather()

func hide_popup():
	hide()
	print("스마트 농업 도우미 팝업 숨김")

# 탭 전환 함수들
func _on_tab_weather_pressed():
	current_tab = "weather"
	layout_popup_elements()
	load_all_weather_data()

func _on_tab_cultivation_pressed():
	current_tab = "cultivation"
	layout_popup_elements()

func _on_region_selected(index: int):
	var region_names = regions.keys()
	if index < region_names.size():
		current_region = region_names[index]
		load_all_weather_data()
		print("선택된 지역: ", current_region)

func _on_crop_selected(index: int):
	var crop_names = crops.keys()
	if index < crop_names.size():
		current_crop = crop_names[index]
		print("선택된 작물: ", current_crop)

func _on_close_pressed():
	hide_popup()

# 재배 조언 관련 함수들
func _on_send_pressed():
	send_cultivation_query()

func _on_chat_input_submitted(text: String):
	send_cultivation_query()

func send_cultivation_query():
	if not chat_input or chat_input.text.strip_edges() == "":
		return
	
	var query = chat_input.text.strip_edges()
	var crop_english = crops.get(current_crop, "tomato")
	
	# 사용자 질문을 채팅에 추가
	add_chat_message("사용자", query, Color.LIGHT_BLUE)
	
	# 입력창 초기화
	chat_input.text = ""
	
	# API 호출
	fetch_cultivation_advice(crop_english, query)

func add_chat_message(sender: String, message: String, color: Color):
	chat_history.append({"sender": sender, "message": message, "color": color})
	update_chat_display()

func update_chat_display():
	if not chat_display:
		return
	
	var content = ""
	for chat in chat_history:
		var color_hex = "#" + chat.color.to_html()
		content += "[color=" + color_hex + "][b]" + chat.sender + ":[/b][/color]\n"
		content += chat.message + "\n\n"
	
	chat_display.text = content
	
	# 스크롤을 맨 아래로
	await get_tree().process_frame
	if chat_display.get_v_scroll_bar():
		chat_display.get_v_scroll_bar().value = chat_display.get_v_scroll_bar().max_value

func fetch_cultivation_advice(crop: String, query: String):
	if is_loading_cultivation:
		return
	
	is_loading_cultivation = true
	add_chat_message("시스템", "답변을 준비 중입니다...", Color.YELLOW)
	
	var api_url = cultivation_api_base + "/cultivation/" + crop
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify({"query": query})
	
	print("재배 조언 API 요청: ", api_url)
	print("요청 데이터: ", json_data)
	
	var error = http_request_cultivation.request(api_url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		is_loading_cultivation = false
		add_chat_message("시스템", "API 요청 실패: " + str(error), Color.RED)

func _on_cultivation_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_loading_cultivation = false
	
	# 로딩 메시지 제거
	if chat_history.size() > 0 and chat_history[-1].sender == "시스템":
		chat_history.pop_back()
	
	print("재배 조언 API 응답 코드: ", response_code)
	
	if response_code != 200:
		add_chat_message("시스템", "서버 오류: " + str(response_code), Color.RED)
		return
	
	var json_string = body.get_string_from_utf8()
	print("받은 재배 조언 데이터: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		add_chat_message("시스템", "응답 데이터 파싱 오류", Color.RED)
		return
	
	var data = json.data
	
	if data is Dictionary and data.has("advice"):
		var answer = data["advice"]
		add_chat_message("🌱 농업 전문가", answer, Color.LIGHT_GREEN)
	else:
		add_chat_message("시스템", "올바르지 않은 응답 형식", Color.RED)

# 기존 날씨 관련 함수들은 그대로 유지
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

func fetch_weather():
	load_all_weather_data()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("날씨 API 응답 코드: ", response_code)
	
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
	print("받은 날씨 데이터: ", json_string)
	
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
	var now_time = data.get("now_time", "시간 정보 없음")
	var temperature = data.get("ta", "온도 정보 없음")
	var wind_speed = data.get("ws", "풍속 정보 없음")
	var wind_direction = data.get("wdKo", "풍향 정보 없음")
	var weather_korean = data.get("wwKo", "날씨 정보 없음")
	var humidity = data.get("hm", "")
	var pressure = data.get("pa", "")
	var update_log = data.get("log", "")
	
	var weather_icon = get_weather_icon_korean(weather_korean)
	
	var content = "[center][color=black]" + weather_icon + " " + current_region + " 현재 날씨[/color][/center]\n\n"
	content += "[color=black]📍 지역:     [/color][color=black]" + current_region + "[/color]\n"
	content += "[color=black]🌡️ 온도:     [/color][color=black]" + str(temperature) + "[/color]\n"
	content += "[color=black]💨 풍속:     [/color][color=black]" + str(wind_speed) + " [/color]\n"
	content += "[color=black]🧭 풍향:     [/color][color=black]" + str(wind_direction) + "[/color]\n"
	content += "[color=black]☁️ 날씨:     [/color][color=black]" + str(weather_korean) + "[/color]\n"
	
	if humidity != "":
		content += "[color=black]💧 습도:     [/color][color=black]" + str(humidity) + "%[/color]\n"
	if pressure != "":
		content += "[color=black]📊 기압:     [/color][color=black]" + str(pressure) + " hPa[/color]\n"
	
	if update_log != "":
		content += "[color=black]📅" + update_log + "[/color]"
	
	weather_display.text = content
	print(current_region + " 현재 날씨 데이터 표시 완료")

func display_forecast_weather(forecast_data: Array):
	if not forecast_display:
		return
		
	if forecast_data.size() < 8:
		forecast_display.text = "[color=red]예보 데이터가 불완전합니다[/color]"
		return
	
	var dates = forecast_data[0]
	var display_dates = forecast_data[2]
	var rain_prob = forecast_data[3]
	var humidity = forecast_data[4]
	var weather_codes = forecast_data[5]
	var min_temps = forecast_data[6] if forecast_data.size() > 6 else {}
	var max_temps = forecast_data[7] if forecast_data.size() > 7 else {}
	
	var content = "[center][color=black]🔮 단기 예보[/color][/center]\n\n"
	
	for i in range(1, min(dates.size(), 5)):
		var date = dates[i]
		var display_date = display_dates[i] if i < display_dates.size() else date
		
		var weather_code = weather_codes.get(date, "1")
		var weather_icon = get_weather_icon_by_code(weather_code)
		
		var temp_info = ""
		if max_temps.has(date) and min_temps.has(date):
			temp_info = str(max_temps[date]) + "/" + str(min_temps[date])
		elif max_temps.has(date):
			temp_info = "최고 " + str(max_temps[date])
		elif min_temps.has(date):
			temp_info = "최저 " + str(min_temps[date])
		
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

func get_weather_icon_by_code(code: String) -> String:
	match code:
		"1":
			return "☀️"
		"2":
			return "🌤️"
		"3":
			return "🌥️"
		"4":
			return "☁️"
		"5", "6", "7":
			return "🌧️"
		"8", "9", "10":
			return "🌨️"
		_:
			return "🌤️"

func _on_refresh_pressed():
	if current_tab == "weather":
		load_all_weather_data()
	else:
		# 재배 조언 탭에서는 채팅 기록 초기화
		chat_history.clear()
		if chat_display:
			chat_display.text = "[center][color=gray]재배 조언을 위해 질문을 입력해주세요![/color][/center]"

func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):
		hide()
