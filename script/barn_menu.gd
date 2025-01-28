extends Control

var current_month = 3  # 3월부터 시작
var current_year = 2024

func _ready():
	update_month_display()
	inventory_text()
	create_calendar()
	update_lettuce_display()
	$menu_window/Button.pressed.connect(func(): hide())
	hide()
	
	var date_label = get_node("/root/Main/UI/blank/Panel/Date")
	if date_label:
		print("Date 노드 찾음")
		date_label.day_changed.connect(_on_day_changed)
	else:
		print("Date 노드를 찾을 수 없음")
		
	z_index = 2


func _on_day_changed():
	var date_node = get_node("/root/Main/UI/blank/Panel/Date")
	if date_node:
		var new_month = date_node.current_date["month"]
		if new_month != current_month:
			current_month = new_month
			update_month_display()
			var grid = $menu_window/calender
			for child in grid.get_children():
				child.queue_free()
			create_calendar()
			
			
# visible 속성이 변경될 때마다 호출되는 함수
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			update_lettuce_display()
			# 날짜 노드 찾기 및 현재 월 업데이트
			var date_node = get_node("/root/Main/UI/blank/Panel/Date")
			if date_node:
				current_month = date_node.current_date["month"]
				update_month_display()
				# 캘린더 재생성
				var grid = $menu_window/calender
				for child in grid.get_children():
					child.queue_free()
				create_calendar()
		
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
		print(count)
		
		lettuce1.visible = count >= 1
		lettuce2.visible = count >= 6
		lettuce3.visible = count >= 11
		
		count_label.text = str(count) + "개"
		
		
func inventory_text():
	var inven_text = $menu_window/inven_text
	inven_text.text = "수확개수"
	
func update_month_display():
	# 월 표시 Label이 있다고 가정
	var month_label = $menu_window/month_label  # Label 노드의 경로에 맞게 수정
	month_label.text = str(current_month) + "월"
	
func create_calendar():
	var grid = $menu_window/calender  # GridContainer 노드가 필요합니다
	
	# 요일 헤더 추가
	var days = ["일", "월", "화", "수", "목", "금", "토"]
	for day in days:
		var label = Label.new()
		label.text = day
		grid.add_child(label)
	
	# 해당 월의 1일의 요일 계산 (0 = 일요일)
	var time = Time.get_unix_time_from_system()
	var date = Time.get_date_dict_from_unix_time(time)
	date.day = 1
	date.month = current_month
	date.year = current_year
	
	# Time.get_unix_time_from_datetime_dict로 변환 후 다시 날짜 얻기
	var unix_time = Time.get_unix_time_from_datetime_dict(date)
	var first_date = Time.get_date_dict_from_unix_time(unix_time)
	var first_day = first_date.weekday - 1  # Godot의 weekday는 1(일요일)부터 시작
	if first_day < 0: first_day = 6
	
	# 1일 전까지 빈 셀 추가
	for i in range(first_day):
		var empty = Label.new()
		empty.text = ""
		grid.add_child(empty)
	
	# 날짜 추가
	var days_in_month = 31  # 3월은 31일까지
	if current_month in [4, 6, 9, 11]:
		days_in_month = 30
	elif current_month == 2:
		days_in_month = 28
		
	for day in range(1, days_in_month + 1):
		var button = Button.new()
		button.text = str(day)
		button.custom_minimum_size = Vector2(50, 50)  # 버튼 크기
		#grid.add_child(button)
		
		 # 물 준 날짜 체크
		var player = get_node("/root/Main/Player")
		if player and player.watered_dates.has(str(current_month) + "_" + str(day)):
			button.modulate = Color(0.5, 0.8, 1.0)  # 파란색으로 표시
	
		grid.add_child(button)
		
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		hide()
