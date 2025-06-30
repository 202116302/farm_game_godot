# Robot.gd - AI 로봇 상호작용 영역 (현재 씬 구조에 맞게 수정)
extends Area2D

@onready var interaction_label = $InteractionUI/Label
@onready var interaction_ui = $InteractionUI
var player_in_area = false
var can_interact = false
var ai_robot_scene = preload("res://scene/AIRobot.tscn")  # AI 대화 창 씬 - 경로 확인 필요!
var ai_robot_instance = null

signal ai_robot_activated

func _ready():
	print("🤖 Robot _ready() 시작")
	
	# 노드 존재 확인
	print("interaction_label 존재:", interaction_label != null)
	print("interaction_ui 존재:", interaction_ui != null)
	
	# 시그널 연결 (Robot Area2D에 직접 연결)
	body_entered.connect(_on_area_entered)
	body_exited.connect(_on_area_exited)
	print("✅ Area2D 시그널 연결 완료")
	
	# 초기 UI 숨기기
	if interaction_ui:
		interaction_ui.visible = false
		print("✅ interaction_ui 숨김 완료")
	else:
		print("❌ interaction_ui가 null")
	
	print("🤖 Robot _ready() 시작")
	
	# AI 로봇 창 인스턴스 생성
	if ai_robot_scene:
		ai_robot_instance = ai_robot_scene.instantiate()
		print("✅ AIRobot 인스턴스 생성 성공")
		
		# === 🆕 더 안전한 추가 방법 시도 ===
		var tree = get_tree()
		if tree:
			var main_scene = tree.current_scene
			if main_scene:
				# 🆕 방법 1: 직접 메인 씬에 추가
				main_scene.add_child(ai_robot_instance)
				print("✅ AIRobot을 메인 씬에 추가 성공")
				print("✅ 메인 씬 이름:", main_scene.name)
				print("✅ 메인 씬 타입:", main_scene.get_class())
				
				# AIRobot의 부모 확인
				print("✅ AIRobot 부모:", ai_robot_instance.get_parent().name if ai_robot_instance.get_parent() else "null")
			else:
				print("❌ 메인 씬을 찾을 수 없음")
		else:
			print("❌ get_tree()가 null")
	else:
		print("❌ ai_robot_scene preload 실패 - 경로를 확인하세요: res://scenes/AIRobot.tscn")
	
	print("AI 로봇 상호작용 시스템 초기화 완료")

func _on_area_entered(body):
	print("🚶 body_entered 감지: ", body.name)
	if body.name == "Player":
		player_in_area = true
		can_interact = true
		show_interaction_ui()
		print("✅ 플레이어가 AI 로봇에 접근했습니다")
	else:
		print("❓ 플레이어가 아닌 객체: ", body.name)

func _on_area_exited(body):
	print("🚶 body_exited 감지: ", body.name)
	if body.name == "Player":
		player_in_area = false
		can_interact = false
		hide_interaction_ui()
		print("✅ 플레이어가 AI 로봇에서 떠났습니다")
	else:
		print("❓ 플레이어가 아닌 객체: ", body.name)

func show_interaction_ui():
	interaction_ui.visible = true
	interaction_label.text = "🤖 [스페이스바] AI 로봇과 대화"
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func hide_interaction_ui():
	interaction_ui.visible = false

func _process(delta):
	if can_interact and Input.is_action_just_pressed("ui_accept"):  # 스페이스바
		print("🎮 스페이스바 입력 감지!")
		print("can_interact: ", can_interact)
		print("ai_robot_instance 존재: ", ai_robot_instance != null)
		
		if ai_robot_instance:
			print("🤖 ai_robot_instance.visible: ", ai_robot_instance.visible)
			# AI 대화 창 토글
			if ai_robot_instance.visible:
				print("🔽 팝업 닫기 시도")
				ai_robot_instance.hide_popup()
			else:
				print("🔼 팝업 열기 시도")
				ai_robot_instance.show_popup()  # 창을 보여주고 결제 확인
		else:
			print("❌ ai_robot_instance가 null입니다!")

# ESC로 강제 닫기 (선택사항)
func _input(event):
	if event.is_action_pressed("ui_cancel") and ai_robot_instance and ai_robot_instance.visible:
		ai_robot_instance.hide_popup()
