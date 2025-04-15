extends CharacterBody2D

@export var speed = 50  # 이동 속도
var direction = Vector2.ZERO
var screen_size

@onready var sprite = $AnimatedSprite2D
@onready var lettuce_detector = $LettuceDetector

func _ready():
		# 스프라이트 노드 확인
	if not sprite:
		push_error("AnimatedSprite2D 노드를 찾을 수 없습니다!")
		return
	
	# Area2D 노드 확인
	if not lettuce_detector:
		push_error("LettuceDetector(Area2D) 노드를 찾을 수 없습니다!")
	else:
		# 시그널 연결
		lettuce_detector.area_entered.connect(_on_lettuce_detector_area_entered)
	# 랜덤 시드 설정
	randomize()
	
	# 화면 크기 가져오기
	screen_size = get_viewport_rect().size
	
	# 타이머 설정
	$Timer.wait_time = randf_range(1.0, 3.0)
	$Timer.start()

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	
func _physics_process(delta):
	# 현재 방향으로 이동
	velocity = direction * speed
	move_and_slide()
	
	# 스프라이트 방향 설정
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		
	if sprite:
		if velocity.length() > 0:
			sprite.play()
		else:
			sprite.pause()  
			
# 상추와 충돌 감지
func _on_lettuce_detector_area_entered(area):
	# 상추의 HarvestArea와 충돌했는지 확인
	if area.get_parent() and area.get_parent().is_in_group("lettuce"):
		var lettuce = area.get_parent()
		print("동물이 상추를 발견했습니다!")
		
		# 상추가 시들지 않았다면 시들게 만듦
		if lettuce.has_method("wither") and not lettuce.is_withered:
			lettuce.wither()
			print("동물이 상추를 먹었습니다!")


# 랜덤한 방향 설정
func _on_timer_timeout():
	# 랜덤 방향 선택 (8방향)
	var angle = randf_range(0, 2 * PI)
	direction = Vector2(cos(angle), sin(angle))
	
	# 가끔 멈추기
	if randf() < 0.2:
		direction = Vector2.ZERO
	
	# 타이머 재설정
	$Timer.wait_time = randf_range(1.0, 3.0)
	$Timer.start()
	
	# 화면 바깥으로 나가지 않도록 체크
	if position.x < 0 or position.x > screen_size.x or position.y < 0 or position.y > screen_size.y:
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)
		direction = -direction  # 방향 반전
