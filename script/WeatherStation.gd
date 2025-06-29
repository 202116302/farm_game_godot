# WeatherStation.gd - 날씨 관측소 영역
extends Area2D

@onready var interaction_label = $InteractionUI/Label
@onready var interaction_ui = $InteractionUI

var player_in_area = false
var weather_data_node  # 기존 WeatherData 노드 참조
var prompt_label: Label
var can_interact = false
var weather_scene = preload("res://scene/WeatherWindow.tscn")  # 날씨 창 씬
var weather_instance = null

signal weather_station_activated

func _ready():
	# 시그널 연결
	body_entered.connect( _on_area_entered)
	body_exited.connect(_on_area_exited)
	
	# 초기 UI 숨기기
	interaction_ui.visible = false
	
	# 기존 WeatherData 노드 찾기
	weather_data_node = get_node("../WeatherData")
	if not weather_data_node:
		print("WeatherData 노드를 찾을 수 없습니다!")
		
	# 날씨 창 인스턴스 생성
	weather_instance = weather_scene.instantiate()
	add_child(weather_instance)  # 현재 노드의 자식으로 추가

func _on_body_entered(body):
	if body.name == "Player":
		player_in_area = true
		show_interaction_ui()


func _on_body_exited(body):
	if body.name == "Player":
		player_in_area = false
		hide_interaction_ui()

func show_interaction_ui():
	interaction_ui.visible = true
	interaction_label.text = "스페이스바"
	
func hide_interaction_ui():
	interaction_ui.visible = false

func _process(delta):
	if can_interact and Input.is_action_just_pressed("ui_accept"):  # 스페이스바
		# 날씨 창 토글
		if weather_instance.visible:
			weather_instance.hide()
		else:
			weather_instance.show_popup()  # 창을 보여주고 데이터 로드
  
func _on_area_entered(body):
	if body.is_in_group("player"):  # 플레이어 노드에 "player" 그룹 추가 필요
		can_interact = true
		#prompt_label.visible = true
		#prompt_label.global_position = Vector2(340, -240)  # 적절한 위치로 조정
		print("플레이어가 날씨 관측소에 접근했습니다")

func _on_area_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		#prompt_label.visible = false
		print("플레이어가 날씨 관측소에서 떠났습니다")
