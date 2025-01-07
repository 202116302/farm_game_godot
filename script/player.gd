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
		
	add_to_group("player")

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
		
	if Input.is_action_pressed("harvest_action"):
		#var lettuce = await get_nearby_lettuce()
		#if lettuce and lettuce.player_in_range and lettuce.is_harvestable:
			#print("d")
			#$AnimatedSprite2D.play()
			#$AnimatedSprite2D.animation = "harvest"
			#await $AnimatedSprite2D.animation_finished
			#lettuce.harvest()
			#harvested_lettuce_count += 1
			#update_harvest_count()
		harvest_nearby_lettuce()

func harvest_nearby_lettuce():
	var center_tile = background_tilemap.local_to_map(global_position)
	
   
	# 주변 타일 확인 (3x3 영역)
	for dx in range(-2, 3):  # -1, 0, 1
		for dy in range(-2, 3):  # -1, 0, 1
			var check_tile = Vector2i(center_tile.x + dx, center_tile.y + dy)
			if planted_crops.has(check_tile):
				var lettuce = planted_crops[check_tile]["instance"]
				if is_instance_valid(lettuce) and lettuce.player_in_range and lettuce.is_harvestable:
					$AnimatedSprite2D.play()
					$AnimatedSprite2D.animation = "harvest"
					await $AnimatedSprite2D.animation_finished
					lettuce.harvest()
					harvested_lettuce_count += 1
					update_harvest_count()
					# 수확된 상추를 planted_crops에서 제거
					planted_crops.erase(check_tile)
					return
				elif not is_instance_valid(lettuce):
					# 이미 제거된 상추는 planted_crops에서 제거
					planted_crops.erase(check_tile)
	

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


func check_over_ten(numbers: Array) -> bool:
	return numbers.any(func(n): return n >= 10)

func get_area_coordinates(center_pos: Vector2i, direction) -> bool:
	var area_positions: Array[Vector2i] = [] 
	var found_positions: Array = []
	# -2부터 +2까지 순회 (5x5 영역)
	if direction == 1: # 위 
		for x in range(-1, 2):  
			for y in range(-2, 0):
				var pos = Vector2i(center_pos.x + x, center_pos.y + y)
				area_positions.append(pos)
	elif direction == 2: # 오른쪽
		for x in range(1, 3):  
			for y in range(-1, 2):
				var pos = Vector2i(center_pos.x + x, center_pos.y + y)
				area_positions.append(pos)
	elif direction == 3: # 아래
		for x in range(-1, 2):  
			for y in range(1, 3):
				var pos = Vector2i(center_pos.x + x, center_pos.y + y)
				area_positions.append(pos)
	elif direction == 4: #왼쪽
		for x in range(-2, 0):  
			for y in range(-1, 2):
				var pos = Vector2i(center_pos.x + x, center_pos.y + y)
				area_positions.append(pos)
				
	for cell_pos in area_positions:
		var cell_source_id = background_tilemap.get_cell_source_id(cell_pos)
		found_positions.append(cell_source_id)

	return check_over_ten(found_positions)

func find_tiles_with_source_id(source_id: int) -> Array[Vector2i]:
	var found_positions: Array[Vector2i] = []
	var used_cells = background_tilemap.get_used_cells()

	
	# 각 셀을 확인
	for cell_pos in used_cells:
		var cell_source_id = background_tilemap.get_cell_source_id(cell_pos)
		if cell_source_id == source_id:
			found_positions.append(cell_pos)
			print("Found tile with source_id ", source_id, " at position: ", cell_pos)
	
	return found_positions

func change_tilled(tile_pos: Vector2i, num):
	var new_source_id = num
	var possible_coords = [
		Vector2i(0, 0),  # 왼쪽 위
		Vector2i(1, 0),  # 오른쪽 위
		Vector2i(0, 1),  # 왼쪽 아래
		Vector2i(1, 1),
		Vector2i(2, 0),  
		Vector2i(0, 2),  
		Vector2i(2, 1),  
		Vector2i(1, 2),
		Vector2i(2, 2)
	]

	for x in range(0, 3):  # 0, 1
		for y in range(0, 3):  # 0, 1
			var target_pos = Vector2i(tile_pos.x + x, tile_pos.y + y)
			# 선택된 좌표로 타일 변경
			var selected_coords = Vector2i(x, y)
			background_tilemap.set_cell(target_pos, new_source_id, selected_coords)
	
func change_to_tilled_soil(tile_pos: Vector2i):
	var hoe_tile = Vector2i(tile_pos.x + 3, tile_pos.y + 3)
	var current_source_id = background_tilemap.get_cell_source_id(hoe_tile)
	var near_tile_1 = get_area_coordinates(hoe_tile, 1)
	var near_tile_2 = get_area_coordinates(hoe_tile, 2)
	var near_tile_3 = get_area_coordinates(hoe_tile, 3)
	var near_tile_4 = get_area_coordinates(hoe_tile, 4)
	
	if current_source_id < 10:
		if near_tile_1 and !near_tile_2 and near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 10)
		elif near_tile_1 and near_tile_2 and !near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 11)
		elif near_tile_1 and !near_tile_2 and !near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 12)
		elif near_tile_1 and !near_tile_2 and !near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 13)
		elif !near_tile_1 and !near_tile_2 and !near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 14)
		elif near_tile_1 and near_tile_2 and !near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 15)
		elif !near_tile_1 and near_tile_2 and !near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 16)
		elif !near_tile_1 and !near_tile_2 and near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 17)
		elif !near_tile_1 and !near_tile_2 and !near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 18)
		elif !near_tile_1 and !near_tile_2 and !near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 19)
		elif !near_tile_1 and near_tile_2 and near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 20)
		elif near_tile_1 and near_tile_2 and near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 21)
		elif near_tile_1 and near_tile_2 and near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 22)
		elif !near_tile_1 and near_tile_2 and near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 23)
		elif near_tile_1 and !near_tile_2 and near_tile_3 and near_tile_4:
			change_tilled(hoe_tile, 24)
		elif !near_tile_1 and near_tile_2 and !near_tile_3 and !near_tile_4:
			change_tilled(hoe_tile, 25)
			
var planted_crops = {}  # Dictionary to track planted lettuce scenes
var lettuce_scene = preload("res://scene/lettuce_scene.tscn") 

func plant_lettuce():
	var tile_pos = background_tilemap.local_to_map(global_position)
	var current_atlas_coords = background_tilemap.get_cell_atlas_coords(tile_pos)
	var target_pos = Vector2i(tile_pos.x + 4, tile_pos.y + 4)
	
	if current_atlas_coords == Vector2i(1, 1):
		# 해당 위치에 이미 심어진 상추가 있는지 확인
		if planted_crops.has(target_pos):
			var existing_lettuce = planted_crops[target_pos]["instance"]
			# 상추가 존재하고 아직 유효한지 확인
			if is_instance_valid(existing_lettuce):
				print("이미 이 위치에 상추가 심어져 있습니다!")
				return  # 이미 상추가 있으면 함수 종료
		
		# 상추가 없으면 새로 심기
		var lettuce = lettuce_scene.instantiate()
		get_node("/root/Main").add_child(lettuce)
		
		var world_pos = background_tilemap.map_to_local(target_pos)
		lettuce.global_position = world_pos
		
		planted_crops[target_pos] = {
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
