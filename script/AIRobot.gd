# AIRobot.gd - AI 대화 창 (WeatherWindow 구조 참고)
extends Control

# 노드 참조 - 실제 AIRobot 씬 구조에 정확히 맞게 수정
@onready var panel = $Panel
@onready var container = $Panel/container
@onready var title_label = $Panel/container/TitleLabel
@onready var money_display = $Panel/container/MoneyDisplay
@onready var info_display = $Panel/container/InfoDisplay
@onready var pay_button = $Panel/container/PayButton
@onready var cancel_button = $Panel/container/CancelButton
@onready var chat_area = $Panel/container/ChatArea
@onready var chat_history = $Panel/container/ChatArea/ChatHistory
@onready var input_field = $Panel/container/ChatArea/InputField
@onready var send_button = $Panel/container/ChatArea/SendButton
@onready var close_chat_button = $Panel/container/ChatArea/CloseChatButton

# AI 대화 설정
var chat_cost = 10000  # 대화 비용
var is_popup_mode = false
var is_chat_mode = false  # 결제 후 채팅 모드인지
var is_ai_typing = false

# AI 응답 템플릿
var ai_responses = [
	"안녕하세요! 농장 일은 어떠신가요? 🌱",
	"상추 키우기가 쉽지 않으시죠? 더 효율적인 방법을 알려드릴까요?",
	"날씨가 농작물에 미치는 영향에 대해 궁금한 점이 있으신가요?",
	"농장 경영에 대한 조언이 필요하시면 언제든 말씀해주세요!",
	"다른 작물도 키워보는 것은 어떨까요? 다양성이 중요해요! 🥕🥬🌽",
	"물주기와 수확 타이밍이 핵심입니다. 도움이 필요하시면 말씀하세요!",
]

func _ready():
	print("🤖 AIRobot _ready() 시작")
	
	# === 실제 노드 구조 디버깅 ===
	print("=== 실제 자식 노드들 ===")
	for child in get_children():
		print("직접 자식: ", child.name, " (타입: ", child.get_class(), ")")
	
	if get_child_count() > 0:
		var first_child = get_child(0)
		print("첫 번째 자식의 자식들:")
		for grandchild in first_child.get_children():
			print("  - ", grandchild.name, " (타입: ", grandchild.get_class(), ")")
			
			if grandchild.get_child_count() > 0:
				print("    ", grandchild.name, "의 자식들:")
				for great_grandchild in grandchild.get_children():
					print("      - ", great_grandchild.name, " (타입: ", great_grandchild.get_class(), ")")
	
	print("=== @onready 변수 확인 ===")
	# 노드 존재 확인
	print("panel 존재:", panel != null, " (", panel, ")")
	print("container 존재:", container != null, " (", container, ")")
	print("title_label 존재:", title_label != null)
	print("money_display 존재:", money_display != null)
	print("info_display 존재:", info_display != null)
	print("pay_button 존재:", pay_button != null)
	print("cancel_button 존재:", cancel_button != null)
	print("chat_area 존재:", chat_area != null)
	print("chat_history 존재:", chat_history != null)
	print("input_field 존재:", input_field != null)
	print("send_button 존재:", send_button != null)
	print("close_chat_button 존재:", close_chat_button != null)
	print("========================")
	
	# 기본 설정
	setup_enhanced_ui()
	
	# 시그널 연결
	if pay_button:
		pay_button.pressed.connect(_on_pay_button_pressed)
		print("✅ pay_button 시그널 연결됨")
	else:
		print("❌ pay_button이 null이어서 시그널 연결 실패")
		
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_button_pressed)
		print("✅ cancel_button 시그널 연결됨")
	else:
		print("❌ cancel_button이 null이어서 시그널 연결 실패")
		
	if send_button:
		send_button.pressed.connect(_on_send_button_pressed)
		print("✅ send_button 시그널 연결됨")
	else:
		print("❌ send_button이 null이어서 시그널 연결 실패")
		
	if close_chat_button:
		close_chat_button.pressed.connect(_on_close_chat_button_pressed)
		print("✅ close_chat_button 시그널 연결됨")
	else:
		print("❌ close_chat_button이 null이어서 시그널 연결 실패")
		
	if input_field:
		input_field.text_submitted.connect(_on_message_sent)
		print("✅ input_field 시그널 연결됨")
	else:
		print("❌ input_field가 null이어서 시그널 연결 실패")
	
	# 초기에는 숨김
	hide()
	z_index = 2
	
	print("🤖 AIRobot _ready() 완료")

func setup_enhanced_ui():
	print("🎨 setup_enhanced_ui() 시작")
	
	# Panel에 WeatherWindow와 유사한 스타일 적용
	if panel:
		var style_box = StyleBoxFlat.new()
		# 더 눈에 띄는 색상으로 변경 (테스트용)
		style_box.bg_color = Color(0.2, 0.2, 0.8, 0.9)  # 파란색 배경 (더 진하게)
		style_box.border_color = Color(1.0, 1.0, 0.0, 1.0)  # 노란색 테두리 (눈에 띄게)
		style_box.border_width_left = 5
		style_box.border_width_right = 5
		style_box.border_width_top = 5
		style_box.border_width_bottom = 5
		style_box.corner_radius_top_left = 15
		style_box.corner_radius_top_right = 15
		style_box.corner_radius_bottom_left = 15
		style_box.corner_radius_bottom_right = 15
		panel.add_theme_stylebox_override("panel", style_box)
		
		# 패널 강제 설정
		panel.visible = true
		panel.modulate = Color.WHITE
		panel.z_index = 1
		
		print("✅ Panel 스타일 설정 완료 (파란색 배경 + 노란색 테두리)")
	else:
		print("❌ panel이 null - 스타일 설정 실패")
	
	# 제목 라벨 설정
	if title_label:
		title_label.text = "🤖 AI 농업 도우미"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_color_override("font_color", Color.WHITE)  # 흰색 글자
		title_label.add_theme_font_size_override("font_size", 20)  # 크게
		print("✅ title_label 설정 완료")
	else:
		print("❌ title_label이 null")
	
	# 정보 표시 설정 (Label/RichTextLabel 구분)
	if info_display:
		if info_display is RichTextLabel:
			info_display.bbcode_enabled = true
			info_display.text = "[center][color=white]🤖 AI 농업 도우미에 오신 것을 환영합니다!\n\n농장 운영과 작물 재배에 대한\n전문적인 조언을 제공해드립니다.\n\n[color=yellow]대화 비용: 10,000원[/color][/color][/center]"
		else:
			# 일반 Label인 경우
			info_display.text = "🤖 AI 농업 도우미에 오신 것을 환영합니다!\n\n농장 운영과 작물 재배에 대한\n전문적인 조언을 제공해드립니다.\n\n대화 비용: 10,000원"
			info_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			info_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			info_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_display.add_theme_color_override("font_color", Color.WHITE)  # 흰색 글자
		
		# 강제 표시
		info_display.visible = true
		info_display.modulate = Color.WHITE
		
		print("✅ info_display 설정 완료 (타입: ", info_display.get_class(), ")")
	else:
		print("❌ info_display가 null")
	
	# 버튼들도 강제 표시
	if pay_button:
		pay_button.text = "💰 대화하기 (10,000원)"
		pay_button.visible = true
		pay_button.modulate = Color.WHITE
		print("✅ pay_button 설정 완료")
	else:
		print("❌ pay_button이 null")
		
	if cancel_button:
		cancel_button.text = "❌ 취소"
		cancel_button.visible = true
		cancel_button.modulate = Color.WHITE
		print("✅ cancel_button 설정 완료")
	else:
		print("❌ cancel_button이 null")
	
	# 기본 크기 설정
	size = Vector2(600, 500)
	print("✅ 기본 크기 설정 완료: ", size)
	print("🎨 setup_enhanced_ui() 완료")

func layout_popup_elements():
	print("🎨 layout_popup_elements() 호출됨")
	print("is_popup_mode:", is_popup_mode)
	
	# === 디버깅: panel 상태 확인 ===
	print("@onready panel 상태: ", panel)
	print("직접 찾기 시도...")
	
	# 직접 노드 찾기 시도 (call_deferred 타이밍 문제 해결)
	if not panel:
		panel = get_node_or_null("Panel")
		print("get_node_or_null('Panel') 결과: ", panel)
	
	if not panel:
		panel = get_node_or_null("panel")
		print("get_node_or_null('panel') 결과: ", panel)
	
	# 자식 노드들 다시 확인
	if not panel and get_child_count() > 0:
		var first_child = get_child(0)
		if first_child is Panel:
			panel = first_child
			print("첫 번째 자식을 panel로 사용: ", panel)
	
	# container도 마찬가지로 다시 찾기
	if panel and not container:
		container = panel.get_node_or_null("container")
		if not container:
			container = panel.get_node_or_null("Container")
		print("container 찾기 결과: ", container)
	
	# 팝업 모드일 때의 레이아웃 (실제 씬 구조에 맞게)
	if is_popup_mode:
		# 기본 화면 크기 사용 (1024x768)
		var screen_size = Vector2(1024, 768)
		
		var popup_size = Vector2(600, 500)
		size = popup_size
		position = (screen_size - popup_size) / 2
		
		print("팝업 크기 설정: ", size)
		print("팝업 위치 설정: ", position)
		
		if panel:
			# Panel을 전체 영역에 맞게 설정
			panel.position = Vector2(0, 0)
			panel.size = popup_size
			print("✅ 패널 설정 완료")
		else:
			print("❌ panel 노드를 찾을 수 없음")
			print("🔍 현재 자식 노드들:")
			for i in range(get_child_count()):
				var child = get_child(i)
				print("  자식 ", i, ": ", child.name, " (", child.get_class(), ")")
		
		if container:
			# container를 Panel 내부에 맞게 설정
			container.position = Vector2(20, 20)
			container.size = Vector2(popup_size.x - 40, popup_size.y - 40)
			print("✅ 컨테이너 설정 완료")
		else:
			print("❌ container 노드를 찾을 수 없음")
		
		# 제목 라벨 위치 조정
		if container and title_label:
			title_label.position = Vector2(10, 10)
			title_label.size = Vector2(container.size.x - 20, 30)
			print("✅ title_label 위치 설정 완료")
		elif title_label:
			print("❌ container가 없어서 title_label 위치 설정 실패")
		else:
			print("❌ title_label이 null")
		
		# 결제 모드와 채팅 모드에 따라 다르게 배치
		if is_chat_mode:
			print("채팅 모드 레이아웃 적용")
			layout_chat_mode()
		else:
			print("결제 모드 레이아웃 적용")
			layout_payment_mode()

func layout_payment_mode():
	# 결제 화면 레이아웃 (실제 노드 구조에 맞게)
	if money_display:
		money_display.visible = true
		money_display.position = Vector2(20, 50)
		money_display.size = Vector2(container.size.x - 40, 30)
		print("✅ money_display 배치 완료")
	
	if info_display:
		info_display.visible = true
		info_display.position = Vector2(20, 90)
		info_display.size = Vector2(container.size.x - 40, 200)
		print("✅ info_display 배치 완료")
	
	if pay_button:
		pay_button.visible = true
		pay_button.position = Vector2(20, 310)
		pay_button.size = Vector2(200, 40)
		print("✅ pay_button 배치 완료")
	
	if cancel_button:
		cancel_button.visible = true
		cancel_button.position = Vector2(240, 310)
		cancel_button.size = Vector2(120, 40)
		print("✅ cancel_button 배치 완료")
	
	# 채팅 영역 숨기기
	if chat_area:
		chat_area.visible = false
		print("✅ chat_area 숨김 완료")

func layout_chat_mode():
	# 채팅 화면 레이아웃 (실제 노드 구조에 맞게)
	if money_display:
		money_display.visible = false
	if info_display:
		info_display.visible = false
	if pay_button:
		pay_button.visible = false
	if cancel_button:
		cancel_button.visible = false
	print("✅ 결제 UI 숨김 완료")
	
	# 채팅 영역 표시
	if chat_area:
		chat_area.visible = true
		chat_area.position = Vector2(20, 50)
		chat_area.size = Vector2(container.size.x - 40, container.size.y - 70)
		print("✅ chat_area 표시 완료")
	
	if chat_history:
		chat_history.position = Vector2(0, 0)
		chat_history.size = Vector2(chat_area.size.x, chat_area.size.y - 60)
		print("✅ chat_history 배치 완료")
	
	if input_field:
		input_field.position = Vector2(0, chat_area.size.y - 50)
		input_field.size = Vector2(chat_area.size.x - 120, 40)
		print("✅ input_field 배치 완료")
	
	if send_button:
		send_button.position = Vector2(chat_area.size.x - 110, chat_area.size.y - 50)
		send_button.size = Vector2(100, 40)
		print("✅ send_button 배치 완료")
	
	if close_chat_button:
		close_chat_button.position = Vector2(container.size.x - 140, 10)
		close_chat_button.size = Vector2(120, 30)
		print("✅ close_chat_button 배치 완료")

func show_popup():
	print("🤖 AIRobot show_popup() 호출됨")
	is_popup_mode = true
	is_chat_mode = false
	
	print("show() 호출 전 - visible:", visible)
	show()
	print("show() 호출 후 - visible:", visible)
	
	# call_deferred 대신 직접 호출 (타이밍 문제 해결)
	layout_popup_elements()
	update_money_display()
	
	# === 디버깅: 화면에 안 보이는 이유 확인 ===
	print("=== 팝업 표시 상태 디버깅 ===")
	print("AIRobot visible:", visible)
	print("AIRobot position:", position)
	print("AIRobot size:", size)
	print("AIRobot modulate:", modulate)
	print("AIRobot z_index:", z_index)
	
	# === 부모 노드 상태 확인 (안전하게) ===
	var current_parent = get_parent()
	var level = 0
	while current_parent and level < 5:
		print("부모 레벨 ", level, ": ", current_parent.name, " (", current_parent.get_class(), ")")
		if current_parent.has_method("get") and current_parent.has_property("visible"):
			print("  - visible:", current_parent.get("visible"))
		if current_parent.has_method("get") and current_parent.has_property("position"):
			print("  - position:", current_parent.get("position"))
		if current_parent.has_method("get") and current_parent.has_property("modulate"):
			print("  - modulate:", current_parent.get("modulate"))
		current_parent = current_parent.get_parent()
		level += 1
	
	if panel:
		print("Panel visible:", panel.visible)
		print("Panel position:", panel.position)
		print("Panel size:", panel.size)
		print("Panel modulate:", panel.modulate)
		print("Panel z_index:", panel.z_index)
	
	# 강제로 맨 앞으로 가져오기
	z_index = 100
	move_to_front()
	
	# 투명도 확실히 설정
	modulate = Color.WHITE
	if panel:
		panel.modulate = Color.WHITE
		panel.visible = true
	
	# 위치 강제 설정 (화면 중앙)
	position = Vector2(200, 100)
	size = Vector2(600, 500)
	
	# === 🆕 CanvasLayer 추가 시도 (안전하게) ===
	call_deferred("try_add_to_canvas_layer")
	
	print("강제 설정 후:")
	print("position:", position)
	print("size:", size)
	print("z_index:", z_index)
	
	# === 🆕 매우 눈에 띄는 테스트 박스 추가 ===
	create_test_box()
	
	print("AI 로봇 팝업 표시됨")

# 🆕 CanvasLayer 추가 시도 (안전한 타이밍)
func try_add_to_canvas_layer():
	print("🎨 try_add_to_canvas_layer() 호출됨")
	
	var tree = get_tree()
	if not tree:
		print("❌ get_tree()가 null - CanvasLayer 추가 실패")
		return
	
	var main_scene = tree.current_scene
	if not main_scene:
		print("❌ current_scene이 null - CanvasLayer 추가 실패")
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # 매우 높은 레이어
	canvas_layer.name = "AIRobotCanvasLayer"
	
	# 현재 부모에서 제거
	var current_parent_node = get_parent()
	if current_parent_node:
		current_parent_node.remove_child(self)
		print("✅ 기존 부모에서 제거 완료")
	
	# CanvasLayer를 메인 씬에 추가
	main_scene.add_child(canvas_layer)
	canvas_layer.add_child(self)
	print("✅ CanvasLayer(100) 추가 완료")
	print("✅ 새 부모:", get_parent().name if get_parent() else "null")

# 🆕 테스트용 눈에 띄는 박스 생성
func create_test_box():
	# 빨간색 테스트 박스 생성
	var test_box = ColorRect.new()
	test_box.color = Color.RED
	test_box.size = Vector2(200, 100)
	test_box.position = Vector2(50, 50)
	test_box.name = "TestBox"
	add_child(test_box)
	
	# 테스트 라벨 추가
	var test_label = Label.new()
	test_label.text = "AI 로봇 테스트"
	test_label.position = Vector2(60, 70)
	test_label.add_theme_color_override("font_color", Color.WHITE)
	test_label.add_theme_font_size_override("font_size", 16)
	add_child(test_label)
	
	print("🔴 빨간색 테스트 박스 생성 완료")
	print("🔴 이 빨간색 박스가 보이나요?")

func hide_popup():
	hide()
	print("AI 로봇 팝업 숨김")

func update_money_display():
	if not money_display:
		return
	
	var player = get_player_node()
	if player:
		var current_money = player.get("money") if "money" in player else 0
		money_display.text = "💰 현재 보유 금액: " + str(current_money) + "원"
		money_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# 돈 부족 시 버튼 상태 변경
		if pay_button:
			if current_money >= chat_cost:
				pay_button.disabled = false
				pay_button.text = "💰 대화하기 (10,000원)"
			else:
				pay_button.disabled = true
				pay_button.text = "💸 돈이 부족합니다"

func get_player_node():
	# 플레이어 노드 찾기 (안전한 방식)
	var player = get_node_or_null("/root/Main/Player")
	if not player:
		# 다른 경로 시도
		player = get_node_or_null("../../../Player")
	if not player:
		# 트리에서 찾기 (get_tree가 null이 아닐 때만)
		var tree = get_tree()
		if tree:
			player = tree.get_first_node_in_group("player")
	return player

func _on_pay_button_pressed():
	var player = get_player_node()
	if not player:
		print("플레이어를 찾을 수 없습니다!")
		return
	
	var current_money = player.get("money") if "money" in player else 0
	
	if current_money < chat_cost:
		show_insufficient_money_message()
		return
	
	# 돈 차감
	if player.has_method("add_money"):
		player.add_money(-chat_cost)
	else:
		player.set("money", current_money - chat_cost)
	
	print("AI 대화 비용 지불: -", chat_cost, "원")
	
	# 채팅 모드로 전환
	enter_chat_mode()

func show_insufficient_money_message():
	if info_display:
		var original_text = info_display.text
		
		if info_display is RichTextLabel:
			# RichTextLabel인 경우 - BBCode 사용
			info_display.text = "[center][color=red]💸 돈이 부족합니다!\n\n현재 보유 금액이 부족해요.\n더 많은 상추를 키워서\n판매해보세요! 🥬\n\n필요 금액: 10,000원[/color][/center]"
		else:
			# 일반 Label인 경우 - 일반 텍스트
			info_display.text = "💸 돈이 부족합니다!\n\n현재 보유 금액이 부족해요.\n더 많은 상추를 키워서\n판매해보세요! 🥬\n\n필요 금액: 10,000원"
			info_display.add_theme_color_override("font_color", Color.ORANGE_RED)
		
		# 3초 후 원래 텍스트로 복원 (Timer 사용 - 안전한 방식)
		if get_parent():
			var timer = Timer.new()
			add_child(timer)
			timer.timeout.connect(func(): 
				if info_display:  # 노드가 아직 유효한지 확인
					info_display.text = original_text
					if not info_display is RichTextLabel:
						info_display.add_theme_color_override("font_color", Color.WHITE)
				timer.queue_free()
			)
			timer.wait_time = 3.0
			timer.one_shot = true
			timer.start()
		else:
			# Timer 추가가 안 되면 call_deferred로 복원
			call_deferred("_restore_info_text", original_text)

func _restore_info_text(original_text: String):
	if info_display:
		info_display.text = original_text
		if not info_display is RichTextLabel:
			info_display.add_theme_color_override("font_color", Color.WHITE)

func enter_chat_mode():
	is_chat_mode = true
	layout_popup_elements()  # call_deferred 제거
	
	# 환영 메시지 추가
	add_welcome_message()
	
	# 입력 필드에 포커스
	if input_field:
		input_field.call_deferred("grab_focus")  # 이건 call_deferred 유지

func add_welcome_message():
	if chat_history:
		var welcome_msg = "[color=lime]🤖 AI: 안녕하세요! AI 농업 도우미입니다! 🌱\n\n농장 운영이나 작물 재배에 대해 궁금한 점이 있으시면 언제든 물어보세요![/color]\n\n"
		chat_history.text += welcome_msg
		scroll_to_bottom()

func _on_cancel_button_pressed():
	hide_popup()

func _on_send_button_pressed():
	if input_field:
		_on_message_sent(input_field.text)

func _on_message_sent(message: String):
	if message.strip_edges() == "":
		return
	
	# 사용자 메시지 추가
	add_user_message(message)
	
	# 입력 필드 클리어
	if input_field:
		input_field.text = ""
	
	# AI 응답 시뮬레이션
	simulate_ai_response(message)

func add_user_message(message: String):
	if chat_history:
		var user_msg = "[color=lightblue]👤 나: " + message + "[/color]\n\n"
		chat_history.text += user_msg
		scroll_to_bottom()

func add_ai_message(message: String):
	if chat_history:
		var ai_msg = "[color=lime]🤖 AI: " + message + "[/color]\n\n"
		chat_history.text += ai_msg
		scroll_to_bottom()

func scroll_to_bottom():
	# 채팅 히스토리를 맨 아래로 스크롤 (노드 타입별 처리)
	if not chat_history:
		print("❌ chat_history가 없음")
		return
	
	# TextEdit인 경우 - 간단한 스크롤
	if chat_history is TextEdit:
		# TextEdit의 스크롤을 맨 아래로
		chat_history.call_deferred("set_v_scroll", 999999)  # 큰 값으로 맨 아래로
		print("✅ TextEdit 스크롤 완료")
		return
	
	# Label/RichTextLabel인 경우 - ScrollContainer 찾기
	var container = null
	var parent1 = chat_history.get_parent()
	
	if parent1 and parent1 is ScrollContainer:
		container = parent1
	elif parent1:
		var parent2 = parent1.get_parent()
		if parent2 and parent2 is ScrollContainer:
			container = parent2
	
	# 스크롤 실행
	if container:
		var v_scroll = container.get_v_scroll_bar()
		if v_scroll:
			container.call_deferred("set_scroll_vertical", v_scroll.max_value)
			print("✅ ScrollContainer 스크롤 완료")
		else:
			print("❌ v_scroll_bar 없음")
	else:
		print("❌ ScrollContainer 없음 - 스크롤 기능 비활성화")

func simulate_ai_response(user_message: String):
	if is_ai_typing:
		return
	
	is_ai_typing = true
	if send_button:
		send_button.disabled = true
	
	# 타이핑 인디케이터
	if chat_history:
		chat_history.text += "[color=yellow]🤖 AI가 입력 중...[/color]\n\n"
		scroll_to_bottom()
	
	# AI 응답 지연 시뮬레이션 (Timer 사용)
	var timer = Timer.new()
	if get_parent():
		add_child(timer)
		timer.timeout.connect(func(): _finish_ai_response(user_message, timer))
		timer.wait_time = randf_range(1.0, 3.0)
		timer.one_shot = true
		timer.start()
	else:
		# Timer 추가가 안 되면 즉시 응답
		call_deferred("_finish_ai_response", user_message, null)

func _finish_ai_response(user_message: String, timer: Timer):
	# 타이핑 인디케이터 제거
	if chat_history:
		var text = chat_history.text
		chat_history.text = text.replace("[color=yellow]🤖 AI가 입력 중...[/color]\n\n", "")
	
	# 응답 생성
	var response = generate_ai_response(user_message)
	
	is_ai_typing = false
	if send_button:
		send_button.disabled = false
	
	# AI 메시지 추가
	add_ai_message(response)
	
	# 타이머 정리
	if timer:
		timer.queue_free()

func generate_ai_response(user_message: String) -> String:
	var message_lower = user_message.to_lower()
	
	# 키워드 기반 응답 (WeatherWindow의 지역별 응답과 유사)
	if "상추" in message_lower:
		return "상추는 시원한 날씨를 좋아해요! 🥬 물을 너무 많이 주지 마시고, 하루에 한 번 정도면 충분합니다. 수확할 때는 뿌리째 뽑지 말고 잎만 따면 계속 자라날 거예요!"
	elif "돈" in message_lower or "판매" in message_lower:
		return "농장 수익을 늘리려면 다양한 작물을 키우는 것이 좋아요! 💰 상추 외에도 당근, 토마토, 옥수수 등을 시도해보세요. 계절별로 다른 작물을 키우면 연중 수입이 가능합니다!"
	elif "날씨" in message_lower:
		return "날씨는 농업에 정말 중요한 요소예요! ☀️🌧️ 비가 올 때는 물주기를 줄이고, 햇볕이 강할 때는 그늘막을 설치하는 것이 좋습니다. 날씨 예보를 자주 확인하세요!"
	elif "안녕" in message_lower:
		return "안녕하세요! 😊 오늘도 농장 일 수고 많으셨어요. 어떤 도움이 필요하신지 말씀해주세요!"
	elif "고마워" in message_lower:
		return "천만에요! 😊 항상 성공적인 농장 운영을 위해 도움을 드리고 싶어요. 다른 궁금한 점이 있으시면 언제든 물어보세요!"
	else:
		return ai_responses[randi() % ai_responses.size()]

func _on_close_chat_button_pressed():
	# 채팅 종료하고 팝업 닫기
	hide_popup()

# ESC 키로 팝업 닫기 (WeatherWindow와 동일)
func _input(event):
	if visible and is_popup_mode and event.is_action_pressed("ui_cancel"):  # ESC
		hide_popup()
