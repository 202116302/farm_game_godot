extends Area2D

@onready var background_tilemap = get_parent().get_node("Background")
var layer_id = 0  # 새로 추가된 레이어 ID 변수

# 괭이질 관련 변수
var is_hoeing = false
var hoe_range = 1  # 괭이질 범위 (타일 단위)

var screensize = Vector2.ZERO

var harvested_lettuce_count = 0  # 수확한 상추 개수
@onready var count_label = get_node("/root/Main/UI/blank/Panel/lettuce")  # Label 노드 참조

func _ready():
# 타일맵 참조 확인
	if not background_tilemap:
		push_error("Background TileMap not found!")
	if count_label:
		print("Label 노드를 찾았습니다")
		update_harvest_count()
	else:
		print("Label 노드를 찾을 수 없습니다")
		push_error("Label 노드를 찾을 수 없습니다")

func _input(event):
# 마우스 클릭 또는 지정된 키를 눌렀을 때 괭이질 실행
	if event.is_action_pressed("hoe_action"):
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "soil"
		hoe_ground()
		
	if Input.is_action_pressed("E"):  # E키는 기본적으로 ui_accept에 매핑되어 있습니다
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "water"
		
	if Input.is_action_pressed("seed_action"):
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "seed"
		plant_lettuce()
   
func get_nearby_lettuce() -> Node2D:
	# 플레이어의 현재 타일 위치
	var center_tile = background_tilemap.local_to_map(global_position)
	
	# 주변 타일 확인 (3x3 영역)
	for dx in range(-1, 2):  # -1, 0, 1
		for dy in range(-1, 2):  # -1, 0, 1
			var check_tile = Vector2i(center_tile.x + dx, center_tile.y + dy)
			if planted_crops.has(check_tile):
				var lettuce = planted_crops[check_tile]["instance"]
				if lettuce and lettuce.player_in_range:
					return lettuce
	return null
	
	if Input.is_action_pressed("harvest_action"):
		#var lettuce = get_node("/root/Main/LettuceScene")
		#var tile_pos = background_tilemap.local_to_map(global_position)
		#var lettuce = planted_crops[tile_pos]["instance"] if planted_crops.has(tile_pos) else null
		#print(lettuce.current_stage)
		#if lettuce and lettuce.player_in_range and lettuce.is_harvestable:
			#$AnimatedSprite2D.play()
			#$AnimatedSprite2D.animation = "harvest" 
			#print("수확 전 성장 단계:", lettuce.current_stage) 
			### 애니메이션이 끝나면 상추를 수확
			#await $AnimatedSprite2D.animation_finished
			#lettuce.harvest()
			## 수확 카운트 증가 및 표시 업데이트
			#harvested_lettuce_count += 1
			#update_harvest_count()
			
				# 각 조건 개별 확인
		#if lettuce:
			#print("상추 찾음")
			#print("player_in_range:", lettuce.player_in_range)
			#print("is_harvestable:", lettuce.is_harvestable)
			#print("current_stage:", lettuce.current_stage)
		#
			#if lettuce.player_in_range:
				#print("플레이어가 수확 범위 안에 있음")
				#if lettuce.is_harvestable:
					#print("수확 가능한 상태임")
					#$AnimatedSprite2D.play()
					#$AnimatedSprite2D.animation = "harvest"
					#await $AnimatedSprite2D.animation_finished
					#lettuce.harvest()
					#harvested_lettuce_count += 1
					#update_harvest_count()
				#else:
					#print("아직 수확할 수 없는 상태")
			#else:
				#print("플레이어가 수확 범위 밖에 있음")
		#else:
			#print("이 위치에 상추가 없음")
			
			
		var lettuce = await get_nearby_lettuce()
		if lettuce and lettuce.player_in_range and lettuce.is_harvestable:
			$AnimatedSprite2D.play()
			$AnimatedSprite2D.animation = "harvest"
			await $AnimatedSprite2D.animation_finished
			lettuce.harvest()
			harvested_lettuce_count += 1
			update_harvest_count()

# 수확 카운트 표시 업데이트 함수
func update_harvest_count():
	count_label.text = "수확한 상추: " + str(harvested_lettuce_count)
	#count_label.text = count_label.text 
	
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
var lettuce_scene = preload("res://scene/lettuce_scene.tscn") 

func plant_lettuce():
	var tile_pos = background_tilemap.local_to_map(global_position)
	var current_atlas_coords = background_tilemap.get_cell_atlas_coords(tile_pos)
	
	if current_atlas_coords == Vector2i(1, 1):
		# 해당 위치에 이미 심어진 상추가 있는지 확인
		if planted_crops.has(tile_pos):
			var existing_lettuce = planted_crops[tile_pos]["instance"]
			# 상추가 존재하고 아직 유효한지 확인
			if is_instance_valid(existing_lettuce):
				print("이미 이 위치에 상추가 심어져 있습니다!")
				return  # 이미 상추가 있으면 함수 종료
		
		# 상추가 없으면 새로 심기
		var lettuce = lettuce_scene.instantiate()
		get_node("/root/Main").add_child(lettuce)
		
		var world_pos = background_tilemap.map_to_local(tile_pos)
		lettuce.global_position = world_pos
		
		planted_crops[tile_pos] = {
			"instance": lettuce,
			"plant_time": Time.get_unix_time_from_system()
		}
		
# 캐릭터 이동 
@export var speed = 400


func _ready_move():
	$AnimatedSprite2D.animation = "default"

func _process(delta):
	var direction = Vector2.ZERO
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
		if $AnimatedSprite2D.animation not in ["water", "seed", "harvest", "soil"]:
			$AnimatedSprite2D.animation = "default"
			
func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation in ["water", "seed", "harvest", "soil"]:
			$AnimatedSprite2D.animation = "default"

func set_screensize(size: Vector2):
	screensize = size
