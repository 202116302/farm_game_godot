extends Node2D

@export var growth_time_per_stage: float = 2.0  # 각 단계별 성장 시간(초)

@onready var sprite: Sprite2D = $LettuceSprite

var current_stage: int = 0
var current_stage_time: float = 0.0
var is_growing: bool = true

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
	
	print("상추 생성됨 - 위치:", global_position, "z-index:", z_index)

func _process(delta):
	if is_growing and current_stage < growth_stages.size() - 1:
		current_stage_time += delta
		
		# 다음 단계로 진행할 시간인지 체크
		if current_stage_time >= growth_time_per_stage:
			advance_to_next_stage()

func advance_to_next_stage():
	current_stage += 1
	current_stage_time = 0.0
	
	# 새로운 단계의 이미지로 교체
	if current_stage < growth_stages.size():
		sprite.texture = growth_stages[current_stage]
		print("상추가 ", current_stage + 1, "단계로 성장했습니다!")
		
	# 완전히 자랐는지 체크
	if current_stage >= growth_stages.size() - 1:
		on_fully_grown()

func on_fully_grown():
	is_growing = false
	print("상추가 완전히 자랐습니다!")

# 외부에서 성장을 제어할 수 있는 메소드들
func start_growing():
	is_growing = true

func pause_growing():
	is_growing = false

func reset_growth():
	current_stage = 0
	current_stage_time = 0.0
	is_growing = true
	sprite.texture = growth_stages[0]

# 현재 성장 단계 반환 (0부터 3까지)
func get_current_stage() -> int:
	return current_stage
