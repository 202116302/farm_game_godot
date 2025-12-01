extends CharacterBody2D

@onready var background_tilemap = get_parent().get_node("Background")
var current_field = null
var current_collision_path = null

var layer_id = 0  # 새로 추가된 레이어 ID 변수

# 괭이질 관련 변수
var is_hoeing = false
var hoe_range = 1  # 괭이질 범위 (타일 단위)

var screensize = Vector2.ZERO

var harvested_lettuce_count = 0  # 수확한 상추 개수
@onready var count_label = get_node("/root/Main/UI/blank/Panel/lettuce")  # Label 노드 참조
@onready var camera = $Camera2D

var money = 0

var can_teleport = false
var teleport_target_position = Vector2.ZERO
var current_teleport_zone = null  # 현재 있는 텔레포트 존
var last_teleport_zone = null 
var camera_following = true 

# 카메라 고정/해제 함수 추가
func lock_camera(lock_position: Vector2):
	if camera:
		camera_following = false
		camera.position_smoothing_enabled = false
		camera.enabled = false  # 플레이어의 카메라 비활성화
		
		# 고정 카메라 위치 설정
		camera.global_position = lock_position
		print("카메라 고정: ", lock_position)

func unlock_camera():
	if camera:
		camera_following = true
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.make_current()
		# 카메라를 다시 플레이어 위치로
		camera.position = Vector2.ZERO  # 상대 위치 초기화
		print("카메라 해제 - 플레이어 추적")
		
		
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

	var feet_area = $feat_area # 플레이어의 자식 노드로 추가된 Area2D
	if feet_area:
		feet_area.area_entered.connect(_on_feet_area_entered)
		feet_area.area_exited.connect(_on_feet_area_exited)
		
	var date_label = get_node("/root/Main/UI/blank/Panel/Date")
	if date_label:
		date_label.day_changed.connect(_on_day_changed)
		
	setup_player_camera()
	
	# 텔레포트 프롬프트 참조
	var teleport_prompt = get_node_or_null("/root/Main/UI/blank/Panel/TeleportPrompt")
	if teleport_prompt:
		teleport_prompt.visible = false
		print("TeleportPrompt Label을 찾았습니다")
	else:
		print("TeleportPrompt Label을 찾을 수 없습니다")
	
	
	
	
func setup_player_camera():
	if camera:
		# 이 카메라를 활성 카메라로 설정
		camera.make_current()
		
		# 부드러운 카메라 이동 설정
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		
		# 기본 줌 설정
		camera.zoom = Vector2(1.0, 1.0)
		
		# 카메라 경계 설정 (농장 맵 크기에 맞게)
		camera.limit_left = -2000
		camera.limit_right = 2000
		camera.limit_top = -1500
		camera.limit_bottom = 1500
		
		print("플레이어 카메라 설정 완료")
	else:
		print("Camera2D 노드를 찾을 수 없습니다!")
		
func _on_day_changed():
	if not background_tilemap:
		return
		
	var used_cells = background_tilemap.get_used_cells()
	for cell in used_cells:
		var current_source_id = background_tilemap.get_cell_source_id(cell)
		if current_source_id == 22:  # 물 준 타일
			background_tilemap.set_cell(cell, 5, Vector2i(0, 0))  # 경작된 상태로 변경 CopyRetryClaude can make mistakes. Please double-check responses.

func _input(event):
# 마우스 클릭 또는 지정된 키를 눌렀을 때 괭이질 실행
	if event.is_action_pressed("hoe_action"):
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "soil"
		hoe_ground()
		
	if Input.is_action_pressed("E"):  # E키는 기본적으로 ui_accept에 매핑되어 있습니다
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "water"
		water_ground()
		
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
		
	if camera and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
	# 줌 인
			camera.zoom = camera.zoom * 1.1
			camera.zoom = camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
	# 줌 아웃
			camera.zoom = camera.zoom * 0.9
			camera.zoom = camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(2.0, 2.0))
			
	if Input.is_action_just_pressed("ui_accept") and can_teleport:
		teleport_to_target()



func enable_teleport(target_pos: Vector2, zone: Area2D = null):
	can_teleport = true
	teleport_target_position = target_pos
	current_teleport_zone = zone
	
	# 텔레포트 존의 프롬프트 표시
	if zone and zone.has_method("show_prompt"):
		zone.show_prompt()
	
	print("스페이스바를 눌러 이동하세요")

func disable_teleport():
		# 텔레포트 존의 프롬프트 숨김
	if current_teleport_zone and current_teleport_zone.has_method("hide_prompt"):
		current_teleport_zone.hide_prompt()
		
	can_teleport = false
	current_teleport_zone = null
	teleport_target_position = Vector2.ZERO
	

	
	print("텔레포트 영역에서 벗어났습니다")

func teleport_to_target():
	if can_teleport and teleport_target_position != Vector2.ZERO:
		# 프롬프트 숨김
		if current_teleport_zone and current_teleport_zone.has_method("hide_prompt"):
			current_teleport_zone.hide_prompt()
		
		# 텔레포트 존 정보 저장
		var source_zone = current_teleport_zone
		
		# 위치 이동
		global_position = teleport_target_position
		print("텔레포트 완료! 위치: ", teleport_target_position)
		
		# 목적지 텔레포트 존 찾기
		await get_tree().create_timer(0.1).timeout
		var target_zone = find_teleport_zone_at_position(teleport_target_position)
		
		# 카메라 모드 설정
		if target_zone and target_zone.has_method("should_lock_camera"):
			if target_zone.should_lock_camera():
				# 카메라 고정
				var lock_pos = target_zone.get_camera_lock_position()
				if lock_pos == Vector2.ZERO:
					lock_pos = teleport_target_position  # 기본값: 텔레포트 목적지
				lock_camera(lock_pos)
			else:
				# 카메라 해제
				unlock_camera()
		else:
			# 기본: 카메라 따라가기
			unlock_camera()
		
		can_teleport = false
		current_teleport_zone = null
		
		
# 특정 위치 근처의 텔레포트 존 찾기
func find_teleport_zone_at_position(pos: Vector2, radius: float = 100.0) -> Area2D:
	var zones = get_tree().get_nodes_in_group("teleport_zone")
	for zone in zones:
		if zone.global_position.distance_to(pos) < radius:
			return zone
	return null
	
	
var watered_dates = {} 

func water_ground():
	if not background_tilemap or not current_field:
		return
			
	var field_collision = current_field.get_node(current_collision_path)
	var center_pos = field_collision.position
	var field_shape = field_collision.shape as RectangleShape2D
	
	var tile_size = Vector2(background_tilemap.tile_set.tile_size)
	var field_pos = background_tilemap.local_to_map(current_field.global_position + center_pos - field_shape.size/2)
	var field_size = field_shape.size / tile_size

	var size_x = int(field_size.x)
	var size_y = int(field_size.y)
	
	for x in range(field_pos.x, field_pos.x + field_size.x):
		for y in range(field_pos.y, field_pos.y + field_size.y):
			var tile_pos = Vector2i(x, y)
			var current_source_id = background_tilemap.get_cell_source_id(tile_pos)
			if current_source_id == 5:  # 경작된 타일인 경우
				background_tilemap.set_cell(tile_pos, 22, Vector2i(0, 0))
				# 현재 날짜 저장
				var date_node = get_node("/root/Main/UI/blank/Panel/Date")
				if date_node:
					var current_day = date_node.get_day()
					var current_month = date_node.get_month()
					watered_dates[str(current_month) + "_" + str(current_day)] = true
					print(watered_dates)
					
				# 해당 타일에 있는 상추에 물 주기
				for lettuce in planted_crops.values():
					if lettuce["instance"] and is_instance_valid(lettuce["instance"]):
						var lettuce_pos = background_tilemap.local_to_map(lettuce["instance"].global_position)
						if lettuce_pos == tile_pos:
							lettuce["instance"].water()
							
				if planted_crops.has(tile_pos):
					var lettuce = planted_crops[tile_pos]["instance"]
					if is_instance_valid(lettuce):
						print("상추를 찾았습니다, water() 호출")
						lettuce.water()
					
func harvest_nearby_lettuce():
	var center_tile = background_tilemap.local_to_map(global_position)

	# 주변 타일 확인 (3x3 영역)
	for dx in range(-2, 3):  # -1, 0, 1
		for dy in range(-2, 3):  # -1, 0, 1
			var check_tile = Vector2i(center_tile.x + dx, center_tile.y + dy)
			if planted_crops.has(check_tile):
				print(check_tile)
				var lettuce = planted_crops[check_tile]["instance"]
				print(lettuce.player_in_range)
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
	


# 수확 카운트 표시 업데이트 함수
func update_harvest_count():
	count_label.text = "수확한 상추: " + str(harvested_lettuce_count)
	#count_label.text = count_label.text 
	
func _on_feet_area_entered(area: Area2D):
	if area.is_in_group("farm_field"):
		current_field = area
		# 현재 충돌한 Area2D의 자식 CollisionShape2D 찾기
		for child in area.get_children():
			if child is CollisionShape2D:
			# NodePath로 경로 저장
				current_collision_path = NodePath(child.name)
				print("충돌한 Collision: ", child.name)
				break
		print("농장 영역(" + area.name + ")에 들어왔습니다")

	if area.is_in_group("teleport_zone"):
		if area.has_method("get_target_position"):
			var target = area.get_target_position()
			enable_teleport(target, area)
	
	
func _on_feet_area_exited(area: Area2D):
	if area.is_in_group("farm_field"):
		if current_field == area:
			current_field = null
		print("농장 영역(" + area.name + ")에서 나갔습니다")
		
	if area.is_in_group("teleport_zone"):
		disable_teleport()

func hoe_ground():
	#if not background_tilemap:
		#return
#
## 플레이어 위치를 타일맵 좌표로 변환
	#var player_tile_pos = background_tilemap.local_to_map(global_position)
	#print("Player tile position: ", player_tile_pos)
#
## 타일 변경
	#change_to_tilled_soil(player_tile_pos)
	
	if not background_tilemap or not current_field:
		return
			
	# 현재 필드의 영역 내 타일만 변경
	var field_collision = current_field.get_node(current_collision_path)
	var center_pos = field_collision.position # 콜리전 중심점 
	
	var field_shape = field_collision.shape as RectangleShape2D
	
	var tile_size = Vector2(background_tilemap.tile_set.tile_size)
	var field_pos = background_tilemap.local_to_map(current_field.global_position + center_pos - field_shape.size/2)
	var field_size = field_shape.size / tile_size

# 정수로 변환하여 범위 계산
	var size_x = int(field_size.x)
	var size_y = int(field_size.y)
	
	# 현재 필드 영역 내의 타일만 변경
	for x in range(field_pos.x, field_pos.x + field_size.x):
		for y in range(field_pos.y, field_pos.y + field_size.y):
			var tile_pos = Vector2i(x, y)
			var current_source_id = background_tilemap.get_cell_source_id(tile_pos)
			if current_source_id < 10:
				background_tilemap.set_cell(tile_pos, 5, Vector2i(0, 0))
				
				
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
	

var planted_crops = {}  # Dictionary to track planted lettuce scenes
var lettuce_scene = preload("res://scene/lettuce_scene.tscn")

func plant_lettuce():
	if not background_tilemap or not current_field:
		return
		
	# FeetArea의 중심점 구하기
	var feet_area = $feat_area/feat_co
	if not feet_area:
		return
		
	# FeetArea의 전역 위치 (중심점) 구하기
	var plant_center = feet_area.global_position
	
	# 전역 위치를 타일맵 좌표로 변환
	var tile_pos = background_tilemap.local_to_map(plant_center)
	
	# 해당 위치의 타일이 경작된 상태인지 확인
	var current_source_id = background_tilemap.get_cell_source_id(tile_pos)
	if current_source_id < 10:  # 경작되지 않은 타일
		print("이 위치는 경작되지 않았습니다!")
		return
		
	# 해당 위치에 이미 심어진 상추가 있는지 확인
	if planted_crops.has(tile_pos):
		var existing_lettuce = planted_crops[tile_pos]["instance"]
		if is_instance_valid(existing_lettuce):
			print("이미 이 위치에 상추가 심어져 있습니다!")
			return
	
	# 상추 심기
	var lettuce = lettuce_scene.instantiate()
	get_node("/root/Main").add_child(lettuce)
	
	# 타일맵 좌표를 월드 좌표로 변환하여 상추 위치 설정
	var world_pos = background_tilemap.map_to_local(tile_pos)
	# 타일 중앙에 위치하도록 타일 크기의 절반을 더함
	world_pos += Vector2(background_tilemap.tile_set.tile_size) / 2
	lettuce.global_position = world_pos
	
	# 심은 상추 정보 저장
	planted_crops[tile_pos] = {
		"instance": lettuce,
		"plant_time": Time.get_unix_time_from_system()
	}
	print("상추를 심었습니다! 위치: ", tile_pos)
		
# 캐릭터 이동 
@export var speed = 400


func _ready_move():
	$AnimatedSprite2D.animation = "default"

func _process(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		$AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		$AnimatedSprite2D.flip_h = false
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
