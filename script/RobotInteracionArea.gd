extends Area2D

# 로봇과의 상호작용을 감지하는 Area2D 스크립트
# 이 스크립트는 로봇 씬의 Area2D 노드에 붙입니다.

@export var robot_dialog_scene: PackedScene  # 인스펙터에서 AIRobot 씬을 할당
var robot_dialog_instance = null

func _ready():
	# 플레이어 감지 시그널 연결
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# AIRobot 대화창 인스턴스 생성
	create_robot_dialog()
	
	print("로봇 상호작용 영역 준비 완료")

func create_robot_dialog():
	# AIRobot 씬을 인스턴스화하여 UI에 추가
	if robot_dialog_scene:
		robot_dialog_instance = robot_dialog_scene.instantiate()
	else:
		# 씬이 할당되지 않은 경우 직접 생성
		robot_dialog_instance = preload("res://scene/AIRobot.tscn").instantiate()
	
	if robot_dialog_instance:
		# UI 노드에 추가 (Main/UI 또는 적절한 UI 컨테이너)
		var ui_node = get_node("/root/Main/UI")
		if ui_node:
			ui_node.add_child(robot_dialog_instance)
			print("로봇 대화창이 UI에 추가됨")
		else:
			# UI 노드가 없으면 Main에 직접 추가
			var main_node = get_node("/root/Main")
			if main_node:
				main_node.add_child(robot_dialog_instance)
				print("로봇 대화창이 Main에 추가됨")

func _on_body_entered(body):
	# 플레이어가 로봇 근처에 들어왔을 때
	if body.name == "Player" and robot_dialog_instance:
		robot_dialog_instance._on_player_entered_area(body)
		print("플레이어가 로봇 상호작용 영역에 진입")

func _on_body_exited(body):
	# 플레이어가 로봇 근처에서 나갔을 때
	if body.name == "Player" and robot_dialog_instance:
		robot_dialog_instance._on_player_exited_area()
		print("플레이어가 로봇 상호작용 영역에서 퇴장")
