extends Area2D

@export var target_position: Vector2
@export var lock_camera: bool = true  # 이 존으로 이동했을 때 카메라 고정 여부
@export var camera_lock_position: Vector2 = Vector2.ZERO  # 카메라 고정 위치 (lock_camera가 true일 때)
@export var use_zone_position_for_camera: bool = true  # 텔레포트 존 위치를 카메라 위치로 사용

@onready var prompt_label = $PromptLabel

func _ready():
	add_to_group("teleport_zone")
	if prompt_label:
		prompt_label.visible = false

func get_target_position() -> Vector2:
	return target_position

func should_lock_camera() -> bool:
	return lock_camera

func get_camera_lock_position() -> Vector2:
	if use_zone_position_for_camera:
		return global_position
	return camera_lock_position

func show_prompt():
	if prompt_label:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
