extends Area2D

@onready var background_tilemap = get_parent().get_node("Background")
var layer_id = 0  # 새로 추가된 레이어 ID 변수

# 괭이질 관련 변수
var is_hoeing = false
var hoe_range = 1  # 괭이질 범위 (타일 단위)

var screensize = Vector2.ZERO

func _ready():
# 타일맵 참조 확인
	if not background_tilemap:
		push_error("Background TileMap not found!")

func _input(event):
# 마우스 클릭 또는 지정된 키를 눌렀을 때 괭이질 실행
	if event.is_action_pressed("hoe_action"):
		hoe_ground()
	

func hoe_ground():
	if not background_tilemap:
		return

# 플레이어 위치를 타일맵 좌표로 변환
	var player_tile_pos = background_tilemap.local_to_map(global_position)
	print("Player tile position: ", player_tile_pos)

# 타일 변경
	change_to_tilled_soil(player_tile_pos)

func change_to_tilled_soil(tile_pos: Vector2i):
	var current_atlas_coords = background_tilemap.get_cell_atlas_coords(tile_pos)
	var current_source_id = background_tilemap.get_cell_source_id(tile_pos)
	
	if current_source_id != -1:
		var new_source_id = 1
		var new_atlas_coords = Vector2i(1, 1)
		background_tilemap.set_cell(tile_pos, new_source_id, new_atlas_coords)

var planted_crops = {}  # Dictionary to track planted lettuce scenes
var lettuce_scene = preload("res://lettuce_scene.tscn") 

func plant_lettuce():
	var tile_pos = background_tilemap.local_to_map(global_position)
	var current_atlas_coords = background_tilemap.get_cell_atlas_coords(tile_pos)
	
	if current_atlas_coords == Vector2i(1, 1):
		if not planted_crops.has(tile_pos):
			var lettuce = get_node("/root/Main/LettuceScene").duplicate()
			get_node("/root/Main").add_child(lettuce)
		
			
			var world_pos = background_tilemap.map_to_local(tile_pos)
			lettuce.global_position = world_pos
			
			planted_crops[tile_pos] = {
				"instance": lettuce,
				"plant_time": Time.get_unix_time_from_system()
			}
			
			lettuce.advance_to_next_stage()
# 캐릭터 이동 
@export var speed = 400


func _ready_move():
	$AnimatedSprite2D.animation = "default"

func _process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("E"):  # E키는 기본적으로 ui_accept에 매핑되어 있습니다
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "water"
		
	if Input.is_action_pressed("seed_action"):
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "seed"
		plant_lettuce()
   
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		$AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
   	
	if direction != Vector2.ZERO:
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "run"
		direction = direction.normalized()
		position += direction * speed * delta
	else:
		# 물주기 애니메이션이 실행 중이 아닐 때만 default 애니메이션으로 변경
		if $AnimatedSprite2D.animation not in ["water", "seed"]:
			$AnimatedSprite2D.animation = "default"
			
func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation in ["water", "seed"]:
			$AnimatedSprite2D.animation = "default"

# 캐릭터 이동 
