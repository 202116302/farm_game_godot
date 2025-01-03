extends Label

var current_date: Dictionary
var timer = 0
const DAY_DURATION = 30  # 30초

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
		# 하루(86400초)를 더함
		var next_time = Time.get_unix_time_from_datetime_dict(current_date) + 86400
		current_date = Time.get_datetime_dict_from_unix_time(next_time)
		update_date_display()

func update_date_display():
	text = str(current_date["month"]) + "월 " + str(current_date["day"]) + "일"

func get_current_date() -> Dictionary:
	return current_date
