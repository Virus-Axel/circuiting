extends Node3D

var lowest_y: Vector3
var highest_y: Vector3
var lowest_x: Vector3
var highest_x: Vector3
var center: Vector3

var pcb_array = []
var max_health = 0
var owner_pubkey: Pubkey
var velocity: Vector2
var location: Vector2
var exploding = false
var explode_amount = 1.0

const MAX_BOARD_HEIGHT = 128
const MAX_BOARD_WIDTH = 64

const component_list = [
	preload("res://components/gun_1.tscn"),
	preload("res://components/engine_1.tscn"),
]


func get_mass_center() -> Vector2:
	var amount := 0
	var mass_total := Vector2i(0, 0)
	for x in range(MAX_BOARD_WIDTH):
		for y in range(MAX_BOARD_HEIGHT):
			if pcb_array[y * MAX_BOARD_WIDTH + x] != 0:
				amount += 1
				mass_total += Vector2i(x, y)
	
	return Vector2(mass_total) / amount

func get_force_from_pos(pos: Vector2i) -> Vector2:
	if pcb_array[pos.y * MAX_BOARD_WIDTH + pos.x] == 3:
		return Vector2(0.0, 1.0)
	else:
		return Vector2()

func get_velocity() -> Vector2:
	var result_force = Vector2(0.0, 0.0)
	var mass_center = get_mass_center()

	for x in range(MAX_BOARD_WIDTH):
		for y in range(MAX_BOARD_HEIGHT):
			if pcb_array[y * MAX_BOARD_WIDTH + x] == 3:
				var engine_force = get_force_from_pos(Vector2i(x, y))
				var angle_to_centrum = (mass_center - Vector2(x, y)).angle()
				var rotational_force = engine_force.length() * cos(angle_to_centrum)
				var velocity_force = engine_force.length() * sin(angle_to_centrum)
				result_force += Vector2(rotational_force, velocity_force)
	
	return result_force
				

func set_pcb_marker(pos: Vector2i):
	if pos.x < MAX_BOARD_WIDTH and pos.x >= 0 and pos.y < MAX_BOARD_HEIGHT and pos.y >= 0:
		var marker = $board.get_node("marker").duplicate()
		marker.position = Vector3(float(pos.x - MAX_BOARD_WIDTH / 2) * 2.0, 1.0, -float(pos.y) * 2.0)
		$pcb_ghosts.add_child(marker)


func activate_ghost_pcb():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, MAX_BOARD_HEIGHT):
		for x in range(0, MAX_BOARD_WIDTH):
			if pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y + 1) * MAX_BOARD_WIDTH + x] == 0:
				set_pcb_marker(Vector2i(x, y + 1))
			if pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y - 1) * MAX_BOARD_WIDTH + x] == 0:
				set_pcb_marker(Vector2i(x, y - 1))
			if pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * MAX_BOARD_WIDTH + x + 1] == 0:
				set_pcb_marker(Vector2i(x + 1, y))
			if pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * MAX_BOARD_WIDTH + x - 1] == 0:
				set_pcb_marker(Vector2i(x - 1, y))

func activate_free_slots():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, MAX_BOARD_HEIGHT):
		for x in range(0, MAX_BOARD_WIDTH):
			if pcb_array[y * MAX_BOARD_WIDTH + x] == 1:
				set_pcb_marker(Vector2i(x, y))

func activate_edge_pcb():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, MAX_BOARD_HEIGHT):
		for x in range(0, MAX_BOARD_WIDTH):
			if (pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y + 1) * MAX_BOARD_WIDTH + x] == 0) or (pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y - 1) * MAX_BOARD_WIDTH + x] == 0) or (pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * MAX_BOARD_WIDTH + x + 1] == 0) or (pcb_array[y * MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * MAX_BOARD_WIDTH + x - 1] == 0):
				set_pcb_marker(Vector2i(x, y))

func set_board_pivot(pivot: Vector3):
	$pieces.position = -pivot
	$Components.position = -pivot

func toggle_build_mode():
	if $Camera3D.current:
		$BuildCamera.make_current()
		set_board_pivot(Vector3(64.0, 0.0, 0.0))
		
	else:
		var mc = get_mass_center()
		set_board_pivot(Vector3(mc.x * 2.0, 0.0, -mc.y * 2.0))
		set_board_pivot(Vector3(64.0, 0.0, 0.0))
		$Camera3D.make_current()

func speed_from_byte(input_byte) -> Vector2:
	var high = input_byte >> 4
	var low = input_byte & 127
	return Vector2(float(high) / 127.0, float(low) / 127.0)
	
func coord_from_byte(input_byte) -> Vector2i:
	var high = input_byte >> 4
	var low = input_byte & 127
	return Vector2i(high, low)
	

func adjust_camera(delta):
	var window_size = get_window().get_viewport().size

	const SHIP_MARGIN := 0.1

	var is_highest_x_in_frustum:bool = $Camera3D.unproject_position(highest_x).x > window_size.x + SHIP_MARGIN * window_size.x
	var is_lowest_x_in_frustum:bool = $Camera3D.unproject_position(lowest_x).x < SHIP_MARGIN * window_size.x;
	var is_highest_y_in_frustum:bool = $Camera3D.unproject_position(highest_y).y > window_size.y - SHIP_MARGIN * window_size.y 
	var is_lowest_y_in_frustum:bool = $Camera3D.unproject_position(lowest_y).y < SHIP_MARGIN * window_size.y
	
	var bot_speed = $Camera3D.unproject_position(highest_y).y - (window_size.y - SHIP_MARGIN * window_size.y)
	var top_speed = SHIP_MARGIN * window_size.y - $Camera3D.unproject_position(lowest_y).y

	
	if is_lowest_x_in_frustum and is_highest_x_in_frustum:
		$Camera3D.position += Vector3(0, 0, 10.0 * delta).rotated(Vector3(1, 0, 0), $Camera3D.rotation.x)
	elif is_highest_x_in_frustum:
		$Camera3D.position.x += 10.0 * delta
	elif is_lowest_x_in_frustum:
		$Camera3D.position.x -= 10.0 * delta
		
	if is_lowest_y_in_frustum and is_highest_y_in_frustum:
		$Camera3D.position += Vector3(0, 0, 10.0 * delta).rotated(Vector3(1, 0, 0), $Camera3D.rotation.x)
	elif is_highest_y_in_frustum:
		if bot_speed > 3.0:
			$Camera3D.position.z += 10.0 * delta
	elif is_lowest_y_in_frustum:
		if top_speed > 3.0:
			$Camera3D.position.z -= 10.0 * delta

	$Camera3D.position.x = 0#center.x

func load_from_account(key):
	var account_info_result = SolanaClient.get_account_info(key)
	if not account_info_result.has("result"):
		return
	account_info_result = account_info_result["result"]
	if not account_info_result.has("value"):
		return
	var encoded_account_data = account_info_result["value"]["data"];
	
	var account_data = SolanaSDK.bs64_decode(encoded_account_data[0])
	
	print(account_data)
	
	owner_pubkey = Pubkey.new_from_string(SolanaSDK.bs58_encode(account_data.slice(0, 32)))
	max_health = account_data.decode_u16(32)
	velocity = speed_from_byte(account_data[34])
	var x_position = account_data.decode_s64(35)
	var y_position = account_data.decode_s64(43)
	
	location = Vector2(x_position, y_position)
	
	const ARRAY_START = 67
	
	for x in range(MAX_BOARD_WIDTH):
		for y in range(MAX_BOARD_HEIGHT):
			set_piece(Vector2i(x, y), account_data[ARRAY_START + y * MAX_BOARD_WIDTH + x])

	var mc = get_mass_center()
	set_board_pivot(Vector3(mc.x * 2.0, 0.0, -mc.y * 2.0))


func set_piece(pos: Vector2i, type: int):
	if type != 0:
		var piece = $board.get_node("normal").duplicate()
		piece.position = Vector3(float(pos.x) * 2.0, 0.0, -float(pos.y) * 2.0)

		if($pieces.get_child_count() == 0):
			highest_x = piece.position
			lowest_x = piece.position
			highest_y = piece.position
			lowest_y = piece.position

		if piece.position.x > highest_x.x:
			highest_x = piece.position
		elif piece.position.x < lowest_x.x:
			lowest_x = piece.position
		if piece.position.z > highest_y.z:
			highest_y = piece.position
		elif piece.position.z < lowest_y.z:
			lowest_y = piece.position
		
		center = Vector3((highest_x.x + lowest_x.x) / 2.0, 0.0, (highest_y.z + lowest_y.z) / 2.0)
		
		print("adding child")
		$pieces.add_child(piece)
	
	if type > 1:
		var piece = component_list[type - 2].instantiate()
		
		piece.position = Vector3(float(pos.x) * 2.0, 0.0, -float(pos.y) * 2.0)
		$Components.add_child(piece)
		
	
	pcb_array[pos.y * MAX_BOARD_WIDTH + pos.x] = type
	

func explode(mag):
	for item in $pieces.get_children():
		item.position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * mag
		item.rotation += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * mag
	for item in $Components.get_children():
		item.position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * mag
		item.rotation += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * mag
	

func _ready():
	$BuildCamera.size *= 10.0
	#$BuildCamera.position.x = MAX_BOARD_WIDTH
	pcb_array.resize(MAX_BOARD_WIDTH * MAX_BOARD_HEIGHT)
	#SolanaClient.set_url("http://127.0.0.1:8899")
	#SolanaClient.set_encoding("base64")

	#load_from_account("2cn9FooLHGBNNDntbgxUW12YMQcpYMVgWBN1yJiTVhoP")
	#set_pcb_marker(Vector2i(0, 0))
	#set_pcb_marker(Vector2i(0, 1))
	#set_pcb_marker(Vector2i(0, 2))
	#activate_ghost_pcb()
	#activate_edge_pcb()
	#toggle_build_mode()

func rotate_ship(angle: float):
	rotation.y += angle


func _process(delta):
	var vel = get_velocity()

	#$pieces.rotation.y -= vel.x * 0.1 * delta
	#$Components.rotation.y = $pieces.rotation.y
	
	position.x -= sin(rotation.y) * vel.y * 5.9 * delta
	position.z -= cos(rotation.y) * vel.y * 5.9 * delta
	#position.z = $pieces.position.z
	#$pieces.transform()

	if exploding:
		
		rotation.y -= vel.x * 0.5 * delta
		#$Components.rotation.y = $pieces.rotation.y
		#explode(explode_amount)
		#explode_amount += 0.08
	else:
		adjust_camera(delta)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		exploding = true

func _on_cursor_cursor_changed(coordinate):
	if $pcb_ghosts.is_position_marked(coordinate):
		$Cursor.set_snap(true)
	else:
		$Cursor.set_snap(false)
