extends Node2D

@onready var sprite: Sprite2D = $LettuceSprite
@onready var harvest_area: Area2D = $HarvestArea 

var current_stage: int = 0
var is_growing: bool = true
var is_harvestable: bool = false  # 수확 가능 상태 추가
var player_in_range: bool = false  # 플레이어 감지
var planting_date  # 상추를 심은 날짜
var planting_month: int  # 심은 월
var planting_day: int    # 심은 일

# 각 월의 일수를 저장
var days_in_month = {
	1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30,
	7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
}

# 4단계 상추 텍스처 배열
var growth_stages: Array[Texture2D] = []

func _ready():
	# 텍스처 로드 및 배열에 추가
	# res:// 경로는 실제 이미지 파일 경로로 수정해야 합니다
	growth_stages = [
		preload("res://asset/lettuces/lettuce0.png"),
		preload("res://asset/lettuces/lettuce1.png"),
		preload("res://asset/lettuces/lettuce2-1.png"),
		preload("res://asset/lettuces/lettuce3-1.png")
	]
	# 초기 이미지 설정
	sprite.texture = growth_stages[0]
	z_index = 1 
	
	# 심은 날짜 저장
	var date_node = get_parent().get_node("/root/Main/UI/blank/Panel/Date")
	if date_node:
		planting_month = date_node.get_month()
		planting_day = date_node.get_day()
		print("상추를 심은 날: ", planting_month, "월 ", planting_day, "일")
	
	harvest_area.area_entered.connect(_on_harvest_area_entered)
	harvest_area.area_exited.connect(_on_harvest_area_exited)
	
	#print("상추 생성됨 - 위치:", global_position, "z-index:", z_index)
	
	if harvest_area:
		print("HarvestArea 노드 찾음")
		harvest_area.monitoring = true
		harvest_area.monitorable = true
		print("HarvestArea 설정 - monitoring:", harvest_area.monitoring, ", monitorable:", harvest_area.monitorable)
	else:
		print("HarvestArea 노드를 찾을 수 없음!")
	
	var connections = harvest_area.get_signal_connection_list("body_entered")
	print("body_entered 신호 연결 상태:", connections)

func _on_harvest_area_entered(area: Area2D):
	print("무언가가 영역에 들어왔습니다:", area.name)
	if area.name == "Player":
		player_in_range = true
		print("플레이어가 상추 수확 범위에 들어왔습니다")

func _on_harvest_area_exited(area: Area2D):
	print("무언가가 영역에 들어왔습니다:", area.name) 
	if area.name == "Player":
		player_in_range = false

func calculate_days_passed(current_month: int, current_day: int) -> int:
	var total_days = 0
	
	if current_month == planting_month:
		# 같은 월이면 단순히 일 차이 계산
		total_days = current_day - planting_day
	else:
		# 심은 달의 남은 일수
		total_days += days_in_month[planting_month] - planting_day
		
		# 중간 달의 일수를 모두 더함
		var month = planting_month + 1
		while month < current_month:
			total_days += days_in_month[month]
			month += 1
		
		# 현재 달의 일수를 더함
		total_days += current_day
	
	return total_days
	
func _process(delta):
	if is_growing and current_stage < growth_stages.size() - 1:
		var date_node = get_parent().get_node("/root/Main/UI/blank/Panel/Date")
		if date_node:
			var current_month = date_node.get_month()
			var current_day = date_node.get_day()
			
			var days_passed = calculate_days_passed(current_month, current_day)
			
			# 디버깅
			#print("현재 날짜: ", current_month, "월 ", current_day, "일")
			#print("심은 날짜: ", planting_month, "월 ", planting_day, "일")
			#print("지난 일수: ", days_passed, "일")
			
			# 7일마다 성장
			var should_be_stage = int(days_passed / 1)
			
			# 성장 단계 업데이트
			if should_be_stage > current_stage and should_be_stage < growth_stages.size():
				print("성장 단계 업데이트: ", current_stage, " -> ", should_be_stage)
				advance_to_next_stage()

func advance_to_next_stage():
	current_stage += 1
	
	# 새로운 단계의 이미지로 교체
	if current_stage < growth_stages.size():
		sprite.texture = growth_stages[current_stage]
		print("상추가 ", current_stage + 1, "단계로 성장했습니다!")
		
	# 완전히 자랐는지 체크
	if current_stage >= growth_stages.size() - 1:
		on_fully_grown()

func on_fully_grown():
	is_growing = false
	is_harvestable = true
	print("상추가 완전히 자랐습니다!")
	print("is_growing:", is_growing)
	print("is_harvestable:", is_harvestable)
	print("current_stage:", current_stage)

# 외부에서 성장을 제어할 수 있는 메소드들
func start_growing():
	is_growing = true

func pause_growing():
	is_growing = false


# 수확 함수 추가
func harvest():
	if is_harvestable and player_in_range:
		print("상추가 수확되었습니다!")
		queue_free()  # 상추 제거

func reset_growth():
	current_stage = 0
	is_growing = true
	sprite.texture = growth_stages[0]

# 현재 성장 단계 반환 (0부터 3까지)
func get_current_stage() -> int:
	return current_stage
