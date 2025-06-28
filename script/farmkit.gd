extends Control

# 시그널 정의
signal farmkit_minimized
signal data_updated(type: String, content)

# 노드 참조
@onready var title_label = $ContentArea/Header/Title
#@onready var minimize_btn = $ContentArea/Header/MinimizeButton
@onready var csv_display = $ContentArea/MainContent/CSVDisplay
@onready var refresh_btn = $ContentArea/Footer/RefreshBtn
@onready var file_dialog = $FileDialog
@onready var auto_refresh_checkbox = null

# 변수
var desktop_path = ""
var is_minimized = false
var current_csv_file = ""

# 자동 새로고침 관련 변수
var auto_refresh_enabled = true
var refresh_interval = 10.0  # 10초
var refresh_timer = 0.0

func _ready():
	# 바탕화면 경로 설정
	desktop_path = OS.get_environment("USERPROFILE") + "\\Desktop\\"
	
	# UI 초기 설정
	setup_farmkit_ui()
	
	# 시그널 연결
	connect_signals()
	
	# 초기 데이터 로드
	auto_load_data()
	
func _process(delta):
	# 자동 새로고침 처리
	if auto_refresh_enabled:
		refresh_timer += delta
		if refresh_timer >= refresh_interval:
			refresh_timer = 0.0
			auto_refresh_data()

func auto_refresh_data():
	print("자동 새로고침 - 센서 데이터 업데이트 중...")
	
	# data.csv 파일 다시 로드
	load_csv_data("test.csv")
	
	# 새로고침 로그 표시
	var current_time = Time.get_time_string_from_system()
	print("자동 새로고침 완료: ", current_time)

# 자동 새로고침 토글 함수
func toggle_auto_refresh():
	auto_refresh_enabled = !auto_refresh_enabled
	refresh_timer = 0.0  # 타이머 리셋
	
	var status = "활성화" if auto_refresh_enabled else "비활성화"
	print("자동 새로고침 ", status)

# 새로고침 간격 설정 함수
func set_refresh_interval(seconds: float):
	refresh_interval = seconds
	refresh_timer = 0.0  # 타이머 리셋
	print("새로고침 간격: ", seconds, "초로 설정")
	
	
func setup_farmkit_ui():
	## 제목 설정
	#title_label.text = "스마트팜 키트"
	#title_label.add_theme_color_override("font_color", Color.WHITE)
	
	
	# CSV 표시 설정
	csv_display.custom_minimum_size = Vector2(400, 150)  # 원하는 크기로 설정
	csv_display.bbcode_enabled = true
	csv_display.scroll_active = true
	csv_display.text = "[center][color=gray]CSV 데이터가 여기에 표시됩니다[/color][/center]"
	
	# 버튼 텍스트 설정
	refresh_btn.text = "새로고침"
	#minimize_btn.text = "─"
	
	# 파일 다이얼로그 설정
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM

func connect_signals():
	# 버튼 시그널 연결
	refresh_btn.pressed.connect(_on_refresh_pressed)
	#minimize_btn.pressed.connect(_on_minimize_pressed)
	
	# 파일 다이얼로그 시그널
	file_dialog.file_selected.connect(_on_file_selected)

func auto_load_data():
	# 바탕화면에서 data.csv 파일 직접 로드
	load_csv_data("test.csv")

func find_csv_files() -> Array:
	var csv_files = []
	var dir = DirAccess.open(desktop_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".csv"):
				csv_files.append(file_name)
			file_name = dir.get_next()
	
	return csv_files
	
	
func load_csv_data_simple(filename: String):
	var full_path = desktop_path + filename
	
	if not FileAccess.file_exists(full_path):
		csv_display.text = "[color=red]CSV 파일을 찾을 수 없습니다: " + filename + "[/color]"
		return
	
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		csv_display.text = "[color=red]파일 열기 실패[/color]"
		return
	
	# 마지막 라인 찾기
	var last_line = ""
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			last_line = line
	
	file.close()
	
	if last_line == "":
		csv_display.text = "[color=red]데이터가 없습니다[/color]"
		return
	
	# 데이터 파싱
	var data = last_line.split(",")
	
	if data.size() < 6:
		csv_display.text = "[color=red]데이터 형식 오류[/color]"
		return
	
	# LED 상태 변환
	var led_text = "꺼짐"
	if data[5].strip_edges() == "1":
		led_text = "켜짐"
	
	# 깔끔한 표시
	#content = "[center][b][color=lightgreen]키트 센서 현황[/color][/b][/center]\n\n"
	
	var content = "[color=white]온도: [/color][color=yellow]" + data[1].strip_edges() + "°C[/color]   "
	content += "[color=white]습도: [/color][color=cyan]" + data[2].strip_edges() + "%[/color]   "
	content += "[color=white]토양수분: [/color][color=lightblue]" + data[3].strip_edges() + "%[/color]\n\n"
	content += "[color=white]광도: [/color][color=orange]" + data[4].strip_edges() + " lux[/color]    "
	
	if led_text == "켜짐":
		content += "[color=white]LED: [/color][color=green]" + led_text + "[/color]\n\n"
	else:
		content += "[color=white]LED: [/color][color=red]" + led_text + "[/color]  "
	
	content += "[color=gray]업데이트: " + Time.get_time_string_from_system() + "[/color]"
	
	csv_display.text = content
	current_csv_file = filename
	
	print("센서 데이터 로드 완료")

# 기존 함수를 간단한 버전으로 교체하려면:
func load_csv_data(filename: String):
	load_csv_data_simple(filename)
	
	
#func load_csv_data(filename: String):
	#var full_path = desktop_path + filename
	#print(full_path)
	#
	#if not FileAccess.file_exists(full_path):
		#csv_display.text = "[color=red]CSV 파일을 찾을 수 없습니다: " + filename + "[/color]"
		#return
	#
	#var file = FileAccess.open(full_path, FileAccess.READ)
	#if file == null:
		#var error_code = FileAccess.get_open_error()
		#csv_display.text = "[color=red]파일 열기 실패: " + str(error_code) + "[/color]"
		#return
	#
	## CSV 내용 포맷팅
	#var content = "[center][b][color=lightgreen]" + filename + "[/color][/b][/center]\n\n"
	#
	#var line_count = 0
	#var is_header = true
	#
	#while not file.eof_reached() and line_count < 12:
		#var line = file.get_line().strip_edges()
		#if line != "":
			#var cells = line.split(",")
			#var formatted_line = ""
			#
			#if is_header:
				#formatted_line = "[color=cyan][b]"
				#for i in range(cells.size()):
					#var cell = cells[i].strip_edges()
					#if cell.length() > 12:  # 긴 텍스트 줄임
						#cell = cell.substr(0, 9) + "..."
					#formatted_line += cell
					#if i < cells.size() - 1:
						#formatted_line += " | "
				#formatted_line += "[/b][/color]\n"
				#is_header = false
			#else:
				#for i in range(cells.size()):
					#var cell = cells[i].strip_edges()
					#if cell.length() > 12:
						#cell = cell.substr(0, 9) + "..."
					#formatted_line += cell
					#if i < cells.size() - 1:
						#formatted_line += " | "
				#formatted_line += "\n"
			#
			#content += formatted_line
			#line_count += 1
	#
	#file.close()
	#
	#csv_display.text = content
	#current_csv_file = filename
	#
	## 시그널 발생
	#data_updated.emit("csv", content)
	#
	#print("CSV 로드 완료: ", filename)

# 버튼 이벤트 핸들러들
func _on_load_csv_pressed():
	file_dialog.clear_filters()
	file_dialog.add_filter("*.csv", "CSV 파일")
	file_dialog.popup_centered(Vector2i(700, 500))

func _on_refresh_pressed():
	auto_load_data()

func _on_minimize_pressed():
	toggle_minimize()

func _on_file_selected(path: String):
	if path.ends_with(".csv"):
		var filename = path.get_file()
		load_csv_data(filename)

# 최소화/복원 기능
func toggle_minimize():
	is_minimized = !is_minimized
	
	if is_minimized:
		# 최소화: 제목만 보이게
		$ContentArea/MainContent.visible = false
		$ContentArea/Footer.visible = false
		#minimize_btn.text = "□"
		size.y = 40
	else:
		# 복원: 전체 보이게
		$ContentArea/MainContent.visible = true
		$ContentArea/Footer.visible = true
		#minimize_btn.text = "─"
		size.y = 300
	
	farmkit_minimized.emit()

# 외부에서 호출 가능한 함수들
func load_specific_csv(filename: String):
	load_csv_data(filename)

func show_farmkit():
	visible = true

func hide_farmkit():
	visible = false

# farmkit 위치 설정 (파란 원 영역에)
func position_in_circle(x: float, y: float, width: float = 1000, height: float = 500):
	position = Vector2(x, y)
	size = Vector2(width, height)
