extends Control

var current_month = 3  # 3월부터 시작
var current_year = 2024

# 상추 판매 관련 변수
var lettuce_price = 2000  # 상추 1개당 2000원

func _ready():
	inventory_text()
	update_lettuce_display()
	setup_selling_system()  # 🆕 판매 시스템 설정
	layout_ui_elements()  # 🆕 UI 요소들 위치 조정
	
	$menu_window/Button.pressed.connect(func(): hide())
	hide()
	
	var date_label = get_node("/root/Main/UI/blank/Panel/Date")
	if date_label:
		print("Date 노드 찾음")
		date_label.day_changed.connect(_on_day_changed)
	else:
		print("Date 노드를 찾을 수 없음")
		
	z_index = 2

# 🆕 UI 요소들 위치 조정
func layout_ui_elements():
	# 창 크기 가져오기
	var menu_window = $menu_window
	if not menu_window:
		return
	
	var window_width = menu_window.size.x
	var window_height = menu_window.size.y
	
	print("창 크기: ", window_width, "x", window_height)
	
	# 상추 관련 UI는 상단에 유지 (기존 위치)
	# 판매 관련 UI들을 하단에 배치
	
	# 판매 버튼 (하단 왼쪽)
	var sell_button = $menu_window/SellButton
	if sell_button:
		sell_button.position = Vector2(500, window_height - 200)
		sell_button.size = Vector2(200, 40)
		print("SellButton 위치 설정: ", sell_button.position)
	
	# 모두 판매 버튼 (하단 가운데)
	var sell_all_button = $menu_window/SellAllButton
	if sell_all_button:
		sell_all_button.position = Vector2(270, window_height - 120)
		sell_all_button.size = Vector2(150, 40)
		print("SellAllButton 위치 설정: ", sell_all_button.position)
	
	# 돈 표시 (하단 중앙)
	var money_label = $menu_window/MoneyLabel
	if money_label:
		money_label.position = Vector2(400, window_height - 150)
		money_label.size = Vector2(300, 30)
		print("MoneyLabel 위치 설정: ", money_label.position)
	
	# 메시지 라벨 (하단 오른쪽)
	var message_label = $menu_window/MessageLabel
	if message_label:
		message_label.position = Vector2(50, window_height - 35)
		message_label.size = Vector2(400, 25)
		message_label.modulate.a = 0.0  # 기본적으로 투명
		print("MessageLabel 위치 설정: ", message_label.position)

# 🆕 판매 시스템 설정
func setup_selling_system():
	# 판매 버튼 시그널 연결
	var sell_button = $menu_window/SellButton
	if sell_button:
		sell_button.pressed.connect(_on_sell_button_pressed)
		sell_button.text = "🥬 상추 1개 판매 (2000원)"
		print("판매 버튼 설정 완료")
	else:
		print("⚠️ SellButton 노드를 찾을 수 없습니다!")
	
	# 모두 판매 버튼 시그널 연결
	var sell_all_button = $menu_window/SellAllButton
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_button_pressed)
		sell_all_button.text = "🥬🥬 모두 판매"
		print("모두 판매 버튼 설정 완료")
	else:
		print("⚠️ SellAllButton 노드를 찾을 수 없습니다!")

# 🆕 판매 버튼 클릭 시
func _on_sell_button_pressed():
	var player = get_node("/root/Main/Player")
	if not player:
		print("플레이어를 찾을 수 없습니다!")
		return
	
	# 상추가 있는지 확인
	if player.harvested_lettuce_count <= 0:
		print("판매할 상추가 없습니다!")
		show_message("😢 판매할 상추가 없습니다!")
		return
	
	# 상추 1개 판매
	player.harvested_lettuce_count -= 1
	
	# 돈 추가 (Player에 money 변수가 있다고 가정)
	if player.has_method("add_money"):
		player.add_money(lettuce_price)
	else:
		# money 변수가 직접 있는 경우
		if "money" in player:
			player.money += lettuce_price
		else:
			# money 변수가 없으면 생성
			var current_money = player.get("money") if "money" in player else 0
			player.set("money", current_money + lettuce_price)
	
	print("상추 1개 판매! +", lettuce_price, "원")
	print("남은 상추:", player.harvested_lettuce_count)
	var current_money = player.get("money") if "money" in player else 0
	print("현재 돈:", current_money)
	
	# UI 업데이트
	update_lettuce_display()
	update_money_display()
	
	# 판매 성공 메시지
	show_message("상추 1개 판매! +" + str(lettuce_price) + "원 💰")

# 🆕 전체 판매 (한 번에 모든 상추 판매)
func _on_sell_all_button_pressed():
	var player = get_node("/root/Main/Player")
	if not player:
		return
	
	var lettuce_count = player.harvested_lettuce_count
	if lettuce_count <= 0:
		show_message("😢 판매할 상추가 없습니다!")
		return
	
	# 모든 상추 판매
	var total_money = lettuce_count * lettuce_price
	player.harvested_lettuce_count = 0
	
	# 돈 추가
	if player.has_method("add_money"):
		player.add_money(total_money)
	else:
		if "money" in player:
			player.money += total_money
		else:
			var current_money = player.get("money") if "money" in player else 0
			player.set("money", current_money + total_money)
	
	print("상추 ", lettuce_count, "개 모두 판매! +", total_money, "원")
	var current_money = player.get("money") if "money" in player else 0
	print("현재 돈:", current_money)
	
	# UI 업데이트
	update_lettuce_display()
	update_money_display()
	
	# 판매 성공 메시지
	show_message("상추 " + str(lettuce_count) + "개 모두 판매! +" + str(total_money) + "원 💰🎉")

# 🆕 돈 표시 업데이트
func update_money_display():
	var money_label = $menu_window/MoneyLabel
	if money_label:
		var player = get_node("/root/Main/Player")
		if player:
			var current_money = player.get("money") if "money" in player else 0
			money_label.text = "💰 보유 금액: " + str(current_money) + "원"
			
			# 텍스트 스타일 적용
			money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			money_label.add_theme_color_override("font_color", Color.DARK_GREEN)
		else:
			money_label.text = "💰 보유 금액: 0원"

# 🆕 메시지 유표시 (임시 라벨로 피드백)
func show_message(message: String):
	var message_label = $menu_window/MessageLabel
	if message_label:
		message_label.text = "✨ " + message
		message_label.modulate.a = 1.0  # 완전 불투명
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message_label.add_theme_color_override("font_color", Color.ORANGE)
		
		# 3초 후 서서히 사라지기
		var tween = create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(message_label, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): message_label.text = "")

func _on_day_changed():
	var date_node = get_node("/root/Main/UI/blank/Panel/Date")
	if date_node:
		var new_month = date_node.current_date["month"]
		if new_month != current_month:
			current_month = new_month
			var grid = $menu_window/calender
			for child in grid.get_children():
				child.queue_free()

# visible 속성이 변경될 때마다 호출되는 함수
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			update_lettuce_display()
			update_money_display()  # 🆕 돈 표시도 업데이트
			layout_ui_elements()  # 🆕 창이 열릴 때마다 위치 재조정
			
			var date_node = get_node("/root/Main/UI/blank/Panel/Date")
			if date_node:
				current_month = date_node.current_date["month"]
				var grid = $menu_window/calender
				for child in grid.get_children():
					child.queue_free()
		
func update_lettuce_display():
	var lettuce1 = $menu_window/lettuce1  # TextureRect
	var lettuce2 = $menu_window/lettuce2  # TextureRect
	var lettuce3 = $menu_window/lettuce3  # TextureRect
	var count_label = $menu_window/inven_count
	
	var player = get_node("/root/Main/Player")
	
	lettuce1.visible = false
	lettuce2.visible = false
	lettuce3.visible = false
	
	if player:
		var count = player.harvested_lettuce_count
		print("현재 상추 개수:", count)
		
		lettuce1.visible = count >= 1
		lettuce2.visible = count >= 6
		lettuce3.visible = count >= 11
		
		count_label.text = str(count) + "개"
		
		# 🆕 판매 버튼 활성화/비활성화
		var sell_button = $menu_window/SellButton
		var sell_all_button = $menu_window/SellAllButton
		
		if sell_button:
			sell_button.disabled = (count <= 0)
			if count <= 0:
				sell_button.text = "🥬 상추 없음 (0개)"
			else:
				sell_button.text = "🥬 상추 1개 판매 (2000원)"
		
		if sell_all_button:
			sell_all_button.disabled = (count <= 0)
			if count <= 0:
				sell_all_button.text = "🥬 판매할 상추 없음"
			else:
				sell_all_button.text = "🥬🥬 모두 판매 (" + str(count) + "개)"

func inventory_text():
	var inven_text = $menu_window/inven_text
	inven_text.text = "상추수확개수"

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		hide()
