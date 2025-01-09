extends Label

var current_date: Dictionary
var timer = 0
const DAY_DURATION = 10  # 30초

func _ready():
	# 시작 날짜를 3월 1일로 설정
	current_date = {
		"year": 2024,
		"month": 3,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	update_date_display()

func _process(delta):
	timer += delta
	
	if timer >= DAY_DURATION:
		timer = 0
		# 다음 날짜 계산
		var next_time = Time.get_unix_time_from_datetime_dict(current_date) + 86400
		var next_date = Time.get_datetime_dict_from_unix_time(next_time)
		
		# 디버깅: 다음 날짜 정보 확인
		#print("Next date dictionary: ", next_date)
		
		# Dictionary 형식 확인 후 할당
		if typeof(next_date) == TYPE_DICTIONARY:
			current_date = next_date
			update_date_display()
		else:
			print("Error: next_date is not a dictionary: ", typeof(next_date))
			print("Value: ", next_date)

func update_date_display():
	# Dictionary 형식 확인
	if typeof(current_date) == TYPE_DICTIONARY:
		if "month" in current_date and "day" in current_date:
			text = str(current_date["month"]) + "월 " + str(current_date["day"]) + "일"
		else:
			print("Error: month or day key not found in dictionary")
			print("Current date content: ", current_date)
	else:
			print("Error: current_date is not a dictionary")
			print("Type: ", typeof(current_date))
			print("Value: ", current_date)

func get_month() -> int:
	if typeof(current_date) == TYPE_DICTIONARY and "month" in current_date:
		return current_date["month"]
	return 1  # 기본값 반환

func get_day() -> int:
	if typeof(current_date) == TYPE_DICTIONARY and "day" in current_date:
		return current_date["day"]
	return 1  # 기본값 반환
