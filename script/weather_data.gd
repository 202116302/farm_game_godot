extends Control

# 노드 참조
@onready var weather_display = $WeatherDisplay
@onready var refresh_button = $RefreshButton
@onready var http_request = $HTTPRequest

# API 설정 (순창 지역 날씨)
var api_url = "http://web01.taegon.kr:7500/weather_now/sunchang"

func _ready():
	## 기본 설정
	setup_simple_ui()
	#
	## 시그널 연결
	refresh_button.pressed.connect(_on_refresh_pressed)
	http_request.request_completed.connect(_on_request_completed)
	#
	## 초기 데이터 로드
	fetch_weather()

func setup_simple_ui():
	# 배경 스타일
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.3, 0.8)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style_box)
	
	# 날씨 표시 설정
	weather_display.bbcode_enabled = true
	weather_display.text = "[center][color=gray]순창 날씨 정보 로딩 중...[/color][/center]"
	
	# 버튼 위치 (우측 상단)
	refresh_button.position = Vector2(size.x - 80, 200)
	refresh_button.size = Vector2(70, 30)
	refresh_button.text = "새로고침"

func fetch_weather():
	print("순창 날씨 API 요청: ", api_url)
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
	var update_log = data.get("log", "")
	
	# 날씨 아이콘 선택
	var weather_icon = get_weather_icon_korean(weather_korean)
	
	var content = "[center][b][color=lightblue]" + weather_icon + " 순창 날씨[/color][/b][/center]\n\n"
	content += "[color=white]온도:     [/color][color=yellow]" + temperature + "[/color]\n"
	content += "[color=white]풍속:     [/color][color=cyan]" + wind_speed + "[/color]\n"
	content += "[color=white]풍향:     [/color][color=lightgreen]" + wind_direction + "[/color]\n"
	content += "[color=white]날씨:     [/color][color=white]" + weather_korean + "[/color]\n\n"
	content += "[color=gray]" + now_time + "[/color]\n"
	
	if update_log != "":
		content += "[color=gray]" + update_log + "[/color]"
	
	weather_display.custom_minimum_size = Vector2(400, 150)
	weather_display.text = content
	print("순창 날씨 데이터 표시 완료")

func get_weather_icon_korean(weather_desc: String) -> String:
	# 한국어 날씨 설명에 따른 아이콘
	if "맑" in weather_desc:
		return "☀️"
	elif "구름조금" in weather_desc or "구름적음" in weather_desc:
		return "🌤️"
	elif "구름많음" in weather_desc or "흐림" in weather_desc:
		return "☁️"
	elif "비" in weather_desc or "소나기" in weather_desc:
		return "🌧️"
	elif "눈" in weather_desc:
		return "🌨️"
	elif "안개" in weather_desc or "박무" in weather_desc:
		return "🌫️"
	elif "천둥" in weather_desc or "번개" in weather_desc:
		return "⛈️"
	else:
		return "🌤️"

func _on_refresh_pressed():
	weather_display.text = "[center][color=yellow]새로고침 중...[/color][/center]"
	fetch_weather()

# 위치 설정
func set_position_simple(x: float, y: float, width: float, height: float):
	position = Vector2(x, y)
	size = Vector2(width, height)
	#
	## 버튼 위치 재조정 - null 체크 추가
	#if refresh_button:
		#refresh_button.position = Vector2(width - 80, 10)
	#else:
		#print("refresh_button이 null입니다!")
