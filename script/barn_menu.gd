extends Control

var current_month = 3  # 3월부터 시작
var current_year = 2024

func _ready():
	create_calendar()
	$menu_window/Button.pressed.connect(func(): queue_free())

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
	for day in range(1, days_in_month + 1):
		var button = Button.new()
		button.text = str(day)
		button.custom_minimum_size = Vector2(50, 50)  # 버튼 크기
		grid.add_child(button)
		
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		queue_free()
