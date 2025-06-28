# WeatherStation.gd - 날씨 관측소 영역
extends Area2D

@onready var interaction_label = $InteractionUI/Label
@onready var interaction_ui = $InteractionUI

var player_in_area = false
var weather_data_node  # 기존 WeatherData 노드 참조

signal weather_station_activated

func _ready():
	# 시그널 연결
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 초기 UI 숨기기
	interaction_ui.visible = false
	
	# 기존 WeatherData 노드 찾기
	weather_data_node = get_node("../WeatherData")
	if not weather_data_node:
		print("WeatherData 노드를 찾을 수 없습니다!")

func _on_body_entered(body):
	if body.name == "Player":
		player_in_area = true
		show_interaction_ui()
		open_weather_popup()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_area = false
		hide_interaction_ui()

func show_interaction_ui():
	interaction_ui.visible = true
	interaction_label.text = "[B] 날씨 관측소"
func hide_interaction_ui():
	interaction_ui.visible = false

func _input(event):
	if player_in_area and Input.is_action_pressed("weather"):  # E키 또는 Enter
		print("ok")
		open_weather_popup()

func open_weather_popup():
	if weather_data_node and weather_data_node.has_method("show_popup"):
		weather_data_node.show_popup()
		print("날씨 관측소 활성화됨")
		weather_station_activated.emit()
	else:
		print("WeatherData 노드를 찾을 수 없거나 show_popup 메서드가 없습니다!")
