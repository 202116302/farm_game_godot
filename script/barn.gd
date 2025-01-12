extends Node2D

# 상호작용 영역과 텍스트를 위한 변수들
var prompt_label: Label
var can_interact = false
var menu_scene = preload("res://scene/barn_menu.tscn")
var menu_instance = null

func _ready():

	var font = load("res://asset/font/font2.ttf")  # .ttf 또는 .otf 파일 경로

	# 프롬프트 텍스트 설정
	prompt_label = Label.new()
	prompt_label.text = "SPACE"
	prompt_label.add_theme_font_override("font", font)
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.visible = false
	add_child(prompt_label)
	
	# 시그널 연결
	$enterance.body_entered.connect(_on_area_entered)
	$enterance.body_exited.connect(_on_area_exited)
	
	menu_instance = menu_scene.instantiate()
	add_child(menu_instance)  # 현재 노드의 자식으로 추가 # 처음에는 숨기기
	
func _process(delta):
	if can_interact and Input.is_action_just_pressed("ui_accept"):  # 스페이스바
		#_show_menu()
		menu_instance.visible = !menu_instance.visible
	
	
	# 프롬프트 텍스트 위치 업데이트
	#if prompt_label.visible:
		#var player = get_node("/root/Main/Player")  # 플레이어 노드 경로 조정 필요
		#prompt_label.global_position = player.global_position + Vector2(0, -100)  # 텍스트 위치 조정

func _on_area_entered(body):
	if body.is_in_group("player"):  # 플레이어 노드에 "player" 그룹 추가 필요
		can_interact = true
		prompt_label.visible = true
		var player = get_node("/root/Main/Player")  # 플레이어 노드 경로 조정 필요
		prompt_label.global_position = Vector2(340, -240) 

func _on_area_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		prompt_label.visible = false

#func _show_menu():
	#var menu = preload("res://scene/barn_menu.tscn").instantiate()
	#add_child(menu)
