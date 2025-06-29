extends Control

# AI 로봇 대화 시스템
var chat_cost = 10000  # 대화 비용 (만원)
var is_player_nearby = false
var player_ref = null

func _ready():
	setup_robot_system()
	layout_ui_elements()
	hide()  # 처음에는 숨김
	z_index = 3  # barn_menu보다 위에 표시

func setup_robot_system():
	# 결제 확인 버튼 연결
	var pay_button = $robot_window/PayButton
	if pay_button:
		pay_button.pressed.connect(_on_pay_button_pressed)
		pay_button.text = "💰 " + str(chat_cost) + "원 지불하고 대화하기"
		print("결제 버튼 설정 완료")
	
	# 취소 버튼 연결
	var cancel_button = $robot_window/CancelButton
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_button_pressed)
		cancel_button.text = "❌ 취소"
		print("취소 버튼 설정 완료")
	
	# 대화 창 닫기 버튼 연결
	var close_chat_button = $robot_window/CloseChatButton
	if close_chat_button:
		close_chat_button.pressed.connect(_on_close_chat_button_pressed)
		close_chat_button.text = "🚪 대화 종료"
		print("대화 종료 버튼 설정 완료")
	
	# 메시지 전송 버튼 연결
	var send_button = $robot_window/SendButton
	if send_button:
		send_button.pressed.connect(_on_send_button_pressed)
		send_button.text = "📤 전송"
		print("메시지 전송 버튼 설정 완료")

func layout_ui_elements():
	var robot_window = $robot_window
	if not robot_window:
		return
	
	var window_width = robot_window.size.x
	var window_height = robot_window.size.y
	
	# 로봇 이미지 (상단 중앙)
	var robot_image = $robot_window/RobotImage
	if robot_image:
		robot_image.position = Vector2(window_width/2 - 50, 20)
		robot_image.size = Vector2(100, 100)
	
	# 현재 돈 표시 (상단 왼쪽)
	var money_label = $robot_window/MoneyLabel
	if money_label:
		money_label.position = Vector2(20, 20)
		money_label.size = Vector2(200, 30)
	
	# 안내 메시지 (중앙 상단)
	var info_label = $robot_window/InfoLabel
	if info_label:
		info_label.position = Vector2(20, 140)
		info_label.size = Vector2(window_width - 40, 60)
		info_label.text = "🤖 AI 로봇과 대화하시겠습니까?\n대화 비용: " + str(chat_cost) + "원"
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_color_override("font_color", Color.BLUE)
	
	# 결제 버튼 (중앙 왼쪽)
	var pay_button = $robot_window/PayButton
	if pay_button:
		pay_button.position = Vector2(50, 220)
		pay_button.size = Vector2(200, 50)
	
	# 취소 버튼 (중앙 오른쪽)
	var cancel_button = $robot_window/CancelButton
	if cancel_button:
		cancel_button.position = Vector2(270, 220)
		cancel_button.size = Vector2(100, 50)
	
	# 대화 영역 (전체 중앙 - 처음에는 숨김)
	var chat_area = $robot_window/ChatArea
	if chat_area:
		chat_area.position = Vector2(20, 140)
		chat_area.size = Vector2(window_width - 40, 300)
		chat_area.visible = false
	
	# 대화 내용 (스크롤 영역)
	var chat_history = $robot_window/ChatArea/ChatHistory
	if chat_history:
		chat_history.position = Vector2(0, 0)
		chat_history.size = Vector2(chat_area.size.x, 200)
		chat_history.text = "🤖 안녕하세요! AI 로봇입니다. 무엇을 도와드릴까요?"
		chat_history.add_theme_color_override("font_color", Color.WHITE)
		chat_history.add_theme_color_override("font_shadow_color", Color.BLACK)
	
	# 입력 창
	var input_field = $robot_window/ChatArea/InputField
	if input_field:
		input_field.position = Vector2(0, 220)
		input_field.size = Vector2(chat_area.size.x - 80, 30)
		input_field.placeholder_text = "메시지를 입력하세요..."
	
	# 전송 버튼
	var send_button = $robot_window/ChatArea/SendButton
	if send_button:
		send_button.position = Vector2(chat_area.size.x - 70, 220)
		send_button.size = Vector2(60, 30)
	
	# 대화 종료 버튼
	var close_chat_button = $robot_window/ChatArea/CloseChatButton
	if close_chat_button:
		close_chat_button.position = Vector2(chat_area.size.x - 100, 260)
		close_chat_button.size = Vector2(90, 30)

# 플레이어가 로봇 근처에 있을 때 호출
func _on_player_entered_area(player):
	is_player_nearby = true
	player_ref = player
	show_interaction_hint()
	print("플레이어가 로봇 근처에 도착")

# 플레이어가 로봇에서 멀어질 때 호출
func _on_player_exited_area():
	is_player_nearby = false
	player_ref = null
	hide_interaction_hint()
	print("플레이어가 로봇에서 멀어짐")

func show_interaction_hint():
	# 상호작용 힌트 표시 (예: 화면에 "스페이스바를 눌러 대화하기" 메시지)
	var hint_label = get_node("/root/Main/UI/InteractionHint")
	if hint_label:
		hint_label.text = "🤖 [스페이스바] 를 눌러 AI 로봇과 대화하기"
		hint_label.visible = true

func hide_interaction_hint():
	var hint_label = get_node("/root/Main/UI/InteractionHint")
	if hint_label:
		hint_label.visible = false

func _input(event):
	# 스페이스바로 대화창 열기
	if event.is_action_pressed("ui_accept") and is_player_nearby:  # 스페이스바
		open_robot_dialog()
	
	# ESC로 대화창 닫기
	elif event.is_action_pressed("ui_cancel") and visible:  # ESC
		hide()

func open_robot_dialog():
	if not player_ref:
		return
	
	# 돈 확인
	var current_money = player_ref.get("money") if "money" in player_ref else 0
	
	# UI 업데이트
	update_money_display()
	
	# 대화 영역 숨기고 결제 화면 표시
	show_payment_screen()
	
	show()
	print("로봇 대화창 열림")

func show_payment_screen():
	# 결제 화면 표시
	var info_label = $robot_window/InfoLabel
	var pay_button = $robot_window/PayButton
	var cancel_button = $robot_window/CancelButton
	var chat_area = $robot_window/ChatArea
	
	if info_label: info_label.visible = true
	if pay_button: pay_button.visible = true
	if cancel_button: cancel_button.visible = true
	if chat_area: chat_area.visible = false

func show_chat_screen():
	# 대화 화면 표시
	var info_label = $robot_window/InfoLabel
	var pay_button = $robot_window/PayButton
	var cancel_button = $robot_window/CancelButton
	var chat_area = $robot_window/ChatArea
	
	if info_label: info_label.visible = false
	if pay_button: pay_button.visible = false
	if cancel_button: cancel_button.visible = false
	if chat_area: chat_area.visible = true

func _on_pay_button_pressed():
	if not player_ref:
		show_message("❌ 플레이어 정보를 찾을 수 없습니다!")
		return
	
	var current_money = player_ref.get("money") if "money" in player_ref else 0
	
	# 돈이 부족한 경우
	if current_money < chat_cost:
		var shortage = chat_cost - current_money
		show_message("💸 돈이 부족합니다! " + str(shortage) + "원이 더 필요해요.")
		print("돈 부족: 현재 ", current_money, "원, 필요 ", chat_cost, "원")
		return
	
	# 돈 차감
	if player_ref.has_method("add_money"):
		player_ref.add_money(-chat_cost)
	else:
		player_ref.set("money", current_money - chat_cost)
	
	print("대화 비용 ", chat_cost, "원 결제 완료")
	print("남은 돈: ", player_ref.get("money") if "money" in player_ref else 0)
	
	# 대화 화면으로 전환
	show_chat_screen()
	update_money_display()
	show_message("💰 결제 완료! AI 로봇과 대화를 시작합니다.")

func _on_cancel_button_pressed():
	hide()
	show_message("🚫 대화를 취소했습니다.")

func _on_close_chat_button_pressed():
	hide()
	show_message("👋 대화를 종료했습니다.")

func _on_send_button_pressed():
	send_message()

func send_message():
	var input_field = $robot_window/ChatArea/InputField
	var chat_history = $robot_window/ChatArea/ChatHistory
	
	if not input_field or not chat_history:
		return
	
	var user_message = input_field.text.strip_edges()
	if user_message == "":
		show_message("📝 메시지를 입력해주세요!")
		return
	
	# 사용자 메시지 추가
	chat_history.text += "\n\n😊 나: " + user_message
	
	# AI 응답 생성 (간단한 예시)
	var ai_response = generate_ai_response(user_message)
	chat_history.text += "\n🤖 AI: " + ai_response
	
	# 입력창 비우기
	input_field.text = ""
	
	# 스크롤을 맨 아래로
	chat_history.scroll_to_line(chat_history.get_line_count() - 1)

# 간단한 AI 응답 생성 (실제로는 더 복잡한 시스템을 구현할 수 있습니다)
func generate_ai_response(user_input: String) -> String:
	var responses = [
		"흥미로운 질문이네요! 더 자세히 설명해주실 수 있나요?",
		"농사에 대해 궁금한 것이 있으시면 언제든 물어보세요!",
		"상추 키우기는 어떠신가요? 잘 자라고 있나요?",
		"날씨가 농사에 많은 영향을 주죠. 오늘 날씨는 어떤가요?",
		"더 효율적인 농사 방법에 대해 알고 싶으시면 말씀해주세요!",
		"건강한 식물을 키우는 비밀은 꾸준한 관심과 사랑이에요.",
		"농업 기술이 발전하면서 더 많은 가능성이 열리고 있어요!"
	]
	
	# 입력에 따른 간단한 키워드 매칭
	var lower_input = user_input.to_lower()
	
	if "상추" in lower_input or "lettuce" in lower_input:
		return "상추는 정말 키우기 쉬운 채소예요! 물을 적당히 주고 햇빛이 잘 드는 곳에서 키우시면 됩니다. 🥬"
	elif "날씨" in lower_input or "weather" in lower_input:
		return "오늘 날씨가 농사하기에 적절한지 확인해보시는 게 좋겠어요. 날씨 데이터를 참고해서 물주기를 조절해보세요! ☀️"
	elif "돈" in lower_input or "money" in lower_input or "수익" in lower_input:
		return "농사로 수익을 올리려면 꾸준히 관리하고 적절한 시기에 판매하는 것이 중요해요! 💰"
	elif "안녕" in lower_input or "hello" in lower_input:
		return "안녕하세요! 오늘도 농사일 열심히 하고 계시는군요. 무엇을 도와드릴까요? 😊"
	elif "감사" in lower_input or "thank" in lower_input:
		return "천만에요! 언제든지 궁금한 것이 있으면 물어보세요. 항상 도움이 되고 싶어요! 🤗"
	else:
		return responses[randi() % responses.size()]

func update_money_display():
	var money_label = $robot_window/MoneyLabel
	if money_label and player_ref:
		var current_money = player_ref.get("money") if "money" in player_ref else 0
		money_label.text = "💰 보유 금액: " + str(current_money) + "원"
		money_label.add_theme_color_override("font_color", Color.GREEN)

func show_message(message: String):
	print("메시지: ", message)
	# 기존 barn_menu의 메시지 시스템을 사용하거나 새로운 메시지 시스템 구현
	var barn_menu = get_node("/root/Main/barn_menu")
	if barn_menu and barn_menu.has_method("show_message"):
		barn_menu.show_message(message)
	else:
		# 자체 메시지 표시 시스템
		var temp_label = Label.new()
		temp_label.text = message
		temp_label.position = Vector2(200, 50)
		temp_label.add_theme_color_override("font_color", Color.YELLOW)
		add_child(temp_label)
		
		# 3초 후 제거
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if temp_label and is_instance_valid(temp_label):
				temp_label.queue_free()
			if timer and is_instance_valid(timer):
				timer.queue_free()
		)
		add_child(timer)
		timer.start()

# visible 속성이 변경될 때마다 호출되는 함수
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			update_money_display()
			layout_ui_elements()
