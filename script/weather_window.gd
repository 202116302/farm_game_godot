extends Control

# 기존 노드 참조
@onready var close_button = $weather_window/container/CloseButton
@onready var title_label = $weather_window/container/TitleLabel
@onready var container = $weather_window/container

# 재배 조언용 노드
@onready var chat_display = $weather_window/container/ChatDisplay
@onready var chat_input = $weather_window/container/ChatInput
@onready var send_button = $weather_window/container/SendButton
@onready var auto_advice_button = $weather_window/container/AutoAdviceButton  # 새로 추가
@onready var http_request_cultivation = $HTTPRequestCultivation
@onready var http_request_weather = $HTTPRequestWeather  # 기상 정보용

# API 설정
var cultivation_api_url = "http://localhost:8000/rag/query"
var weather_api_url = "http://34.229.121.126:8000/api/weather/latest"

var is_popup_mode = false

# API 로딩 상태 관리
var is_loading_cultivation = false
var is_loading_weather = false

# 채팅 기록
var chat_history = []

# 현재 기상 데이터
var current_weather_data = null

func _ready():
	## 기본 설정
	setup_enhanced_ui()
	
	## 시그널 연결
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# 재배 조언 관련 시그널 연결
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_input_submitted)
	if auto_advice_button:
		auto_advice_button.pressed.connect(_on_auto_advice_pressed)
	
	if http_request_cultivation:
		http_request_cultivation.request_completed.connect(_on_cultivation_request_completed)
	if http_request_weather:
		http_request_weather.request_completed.connect(_on_weather_request_completed)
	
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
	
	# 채팅 표시 설정
	if chat_display:
		chat_display.bbcode_enabled = true
		chat_display.text = "[center][color=black]재배 조언을 위해 질문을 입력하거나\n'현재 환경 보광 조언' 버튼을 눌러보세요![/color][/center]"
		
		# 글자 크기 설정
		var font_size_override = 16  # 기본보다 조금 큰 크기
		chat_display.add_theme_font_size_override("normal_font_size", font_size_override)
		chat_display.add_theme_font_size_override("bold_font_size", font_size_override + 2)
	
	# 채팅 입력창 설정
	if chat_input:
		chat_input.placeholder_text = "예: 상추 재배 시 광 부족 시 보광 기준 설명해줘"
	
	# 제목 라벨 설정
	if title_label:
		title_label.text = "🌱 재배 조언 도우미"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	# 기존 레이아웃 유지
	layout_popup_elements()

func layout_popup_elements():
	# 기존과 동일한 팝업 크기
	var popup_size = Vector2(700, 500)
	size = popup_size
	container.position = Vector2(60, 120)
	
	# 제목과 닫기 버튼 (기존 위치 유지)
	if title_label:
		title_label.position = Vector2(70, -20)
		title_label.size = Vector2(size.x - 100, 30)
	
	if close_button:
		close_button.position = Vector2(size.x - 40, -20)
		close_button.size = Vector2(60, 30)
		close_button.text = "✕"
	
	# 컨텐츠 영역
	var content_top = 20
	var content_height = size.y - content_top - 10
	
	# 자동 조언 버튼 추가 (상단)
	if auto_advice_button:
		auto_advice_button.position = Vector2(80, content_top)
		auto_advice_button.size = Vector2(200, 35)
		auto_advice_button.text = "🌞 현재 환경 보광 조언"
		auto_advice_button.show()
	
	# 채팅 표시 영역
	if chat_display:
		chat_display.position = Vector2(80, content_top + 45)
		chat_display.size = Vector2(size.x - 80, content_height - 95)
		chat_display.show()
	
	# 입력창과 전송 버튼 (기존 위치 유지)
	if chat_input:
		chat_input.position = Vector2(80, content_top + content_height - 40)
		chat_input.size = Vector2(size.x - 160, 30)
		chat_input.show()
	
	if send_button:
		send_button.position = Vector2(size.x - 50, content_top + content_height - 40)
		send_button.size = Vector2(80, 30)
		send_button.text = "전송"
		send_button.show()

func show_popup():
	is_popup_mode = true
	layout_popup_elements()
	show()
	print("재배 조언 도우미 팝업 표시됨")

func hide_popup():
	hide()
	print("재배 조언 도우미 팝업 숨김")

func _on_close_pressed():
	hide_popup()

# 자동 조언 버튼 클릭
func _on_auto_advice_pressed():
	# 기상 정보를 먼저 가져옴
	add_chat_message("시스템", "현재 기상 정보를 확인하는 중...", Color(0.2, 0.2, 0.2))
	fetch_weather_data()

# 기상 정보 가져오기
func fetch_weather_data():
	if is_loading_weather:
		return
	
	is_loading_weather = true
	
	print("기상 정보 API 요청: ", weather_api_url)
	
	var error = http_request_weather.request(weather_api_url)
	if error != OK:
		is_loading_weather = false
		add_chat_message("시스템", "기상 정보를 가져올 수 없습니다: " + str(error), Color.RED)

# 기상 정보 응답 처리
func _on_weather_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_loading_weather = false
	
	# 로딩 메시지 제거
	if chat_history.size() > 0 and chat_history[-1].sender == "시스템":
		chat_history.pop_back()
	
	print("기상 정보 API 응답 코드: ", response_code)
	
	if response_code != 200:
		add_chat_message("시스템", "기상 정보 서버 오류: " + str(response_code), Color.RED)
		return
	
	var json_string = body.get_string_from_utf8()
	print("받은 기상 데이터: ", json_string)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		add_chat_message("시스템", "기상 데이터 파싱 오류", Color.RED)
		return
	
	current_weather_data = json.data
	
	# 기상 정보를 바탕으로 자동 질문 생성
	create_auto_advice_query()

# 기상 정보 기반 자동 질문 생성
func create_auto_advice_query():
	if not current_weather_data:
		add_chat_message("시스템", "기상 데이터를 사용할 수 없습니다", Color.RED)
		return
	
	var temp = current_weather_data.get("temp", "알 수 없음")
	var humid = current_weather_data.get("humid", "알 수 없음")
	var radn = current_weather_data.get("radn", "알 수 없음")
	var rainfall = current_weather_data.get("rainfall", "알 수 없음")
	
	# 사용자에게 현재 환경 표시
	var env_info = "📊 현재 환경:\n"
	env_info += "- 온도: " + str(temp) + "°C\n"
	env_info += "- 습도: " + str(humid) + "%\n"
	env_info += "- 일사량: " + str(radn) + " W/m²\n"
	env_info += "- 강우량: " + str(rainfall) + " mm"
	
	add_chat_message("현재 환경", env_info, Color(0.2, 0.4, 0.6))
	
	# 자동 질문 생성
	var auto_query = "현재 온도 " + str(temp) + "°C, 습도 " + str(humid) + "%, "
	auto_query += "일사량 " + str(radn) + " W/m², 강우량 " + str(rainfall) + " mm 인 환경에서 "
	auto_query += "상추 재배 시 보광이 필요한지, 그리고 어떤 환경 제어가 필요한지 조언해줘"
	
	# 자동 질문 표시
	add_chat_message("자동 질문", auto_query, Color(0.3, 0.5, 0.7))
	
	# API 호출
	fetch_cultivation_advice(auto_query)

# 재배 조언 관련 함수들
func _on_send_pressed():
	send_cultivation_query()

func _on_chat_input_submitted(text: String):
	send_cultivation_query()

func send_cultivation_query():
	if not chat_input or chat_input.text.strip_edges() == "":
		return
	
	var query = chat_input.text.strip_edges()
	
	# 사용자 질문을 채팅에 추가
	add_chat_message("사용자", query, Color(0.2, 0.4, 0.8))
	
	# 입력창 초기화
	chat_input.text = ""
	
	# API 호출
	fetch_cultivation_advice(query)

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
		content += "[color=black]" + chat.message + "[/color]\n\n"
	
	chat_display.text = content
	
	# 스크롤을 맨 아래로
	await get_tree().process_frame
	if chat_display.get_v_scroll_bar():
		chat_display.get_v_scroll_bar().value = chat_display.get_v_scroll_bar().max_value

func fetch_cultivation_advice(query: String):
	if is_loading_cultivation:
		return
	
	is_loading_cultivation = true
	add_chat_message("시스템", "답변을 준비 중입니다...", Color(0.6, 0.6, 0.0))
	
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify({"question": query})
	
	print("재배 조언 API 요청: ", cultivation_api_url)
	print("요청 데이터: ", json_data)
	
	var error = http_request_cultivation.request(cultivation_api_url, headers, HTTPClient.METHOD_POST, json_data)
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
	
	# 새로운 API 형식에 맞춰 answer 필드 사용
	if data is Dictionary and data.has("answer"):
		var answer = data["answer"]
		add_chat_message("🌱 농업 챗봇", answer, Color(0.0, 0.5, 0.0))
		
		# 출처 정보가 있으면 표시 (선택사항)
		if data.has("sources") and data["sources"] is Array and data["sources"].size() > 0:
			var sources_list = []
			for source in		 data["sources"]:
				sources_list.append(str(source))
			var sources_text = "\n[color=gray][i]📚 참고: " + ", ".join(sources_list) + "[/i][/color]"
			# 마지막 메시지에 출처 추가
			if chat_history.size() > 0:
				chat_history[-1].message += sources_text
			update_chat_display()
	else:
		add_chat_message("시스템", "올바르지 않은 응답 형식", Color.RED)

func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):
		hide_popup()
