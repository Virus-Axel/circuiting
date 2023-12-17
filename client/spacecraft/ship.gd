extends Node3D

var lowest_y: Vector3
var highest_y: Vector3
var lowest_x: Vector3
var highest_x: Vector3
var center: Vector3

var pcb_array = []
var pcb_meta = []
var score = 0

var estimated_rotational_force := 0.0
var estimated_rocket_force := Vector2(0.0, 0.0)

var previous_position := Vector2(0, 0)
var previous_rotation := 0.0

var max_health = 0
var previous_health
var previous_timestamp = 0

var owner_pubkey: Pubkey
var velocity: Vector2
var location: Vector2
var exploding = false
var explode_amount = 1.0
var explode_velocities_piece := []
var explode_rotations_piece := []

var explode_velocities_component := []
var explode_rotations_component := []

signal needs_respawn
signal enemy_needs_revive
signal place_rewards(time: int, key: PackedByteArray)

const component_list = [
	preload("res://components/gun_1.tscn"),
	preload("res://components/engine_1.tscn"),
]

func get_mass_center() -> Vector2:
	var amount := 0
	var mass_total := Vector2i(0, 0)
	for x in range(w3.MAX_BOARD_WIDTH):
		for y in range(w3.MAX_BOARD_HEIGHT):
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0:
				amount += 1
				mass_total += Vector2i(x, y)
	
	return Vector2(mass_total) / amount

func get_force_from_pos(pos: Vector2i) -> Vector2:
	if pcb_array[(pos.y * w3.MAX_BOARD_WIDTH + pos.x)] == 3:
		var is_engine_on = pcb_meta[(pos.y * w3.MAX_BOARD_WIDTH + pos.x)]
		return Vector2(0.0, 1.0) * is_engine_on
	else:
		return Vector2()

func get_velocity() -> Vector2:
	var result_force = Vector2(0.0, 0.0)
	var mass_center = get_mass_center()

	for x in range(w3.MAX_BOARD_WIDTH):
		for y in range(w3.MAX_BOARD_HEIGHT):
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] == 3:
				var engine_force = get_force_from_pos(Vector2i(x, y))
				var angle_to_centrum = (mass_center - Vector2(x, y)).angle()
				var rotational_force = engine_force.length() * cos(angle_to_centrum)
				var velocity_force = engine_force.length() * sin(angle_to_centrum)
				result_force += Vector2(rotational_force, velocity_force)
	
	return result_force
				

func set_pcb_marker(pos: Vector2i):
	if pos.x < w3.MAX_BOARD_WIDTH and pos.x >= 0 and pos.y < w3.MAX_BOARD_HEIGHT and pos.y >= 0:
		var marker = $board.get_node("marker").duplicate()
		marker.position = Vector3(float(pos.x - w3.MAX_BOARD_WIDTH / 2) * 2.0, 1.0, -float(pos.y) * 2.0)
		$pcb_ghosts.add_child(marker)


func activate_ghost_pcb():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, w3.MAX_BOARD_HEIGHT):
		for x in range(0, w3.MAX_BOARD_WIDTH):
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y + 1) * w3.MAX_BOARD_WIDTH + x] == 0:
				set_pcb_marker(Vector2i(x, y + 1))
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y - 1) * w3.MAX_BOARD_WIDTH + x] == 0:
				set_pcb_marker(Vector2i(x, y - 1))
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * w3.MAX_BOARD_WIDTH + x + 1] == 0:
				set_pcb_marker(Vector2i(x + 1, y))
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * w3.MAX_BOARD_WIDTH + x - 1] == 0:
				set_pcb_marker(Vector2i(x - 1, y))

func activate_free_slots():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, w3.MAX_BOARD_HEIGHT):
		for x in range(0, w3.MAX_BOARD_WIDTH):
			if pcb_array[y * w3.MAX_BOARD_WIDTH + x] == 1:
				set_pcb_marker(Vector2i(x, y))

func activate_edge_pcb():
	$pcb_ghosts.clear_markers()
	var top_found := false
	for y in range(0, w3.MAX_BOARD_HEIGHT):
		for x in range(0, w3.MAX_BOARD_WIDTH):
			if (pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y + 1) * w3.MAX_BOARD_WIDTH + x] == 0) or (pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[(y - 1) * w3.MAX_BOARD_WIDTH + x] == 0) or (pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * w3.MAX_BOARD_WIDTH + x + 1] == 0) or (pcb_array[y * w3.MAX_BOARD_WIDTH + x] != 0 and pcb_array[y * w3.MAX_BOARD_WIDTH + x - 1] == 0):
				set_pcb_marker(Vector2i(x, y))

func set_board_pivot(pivot: Vector3):
	$pieces.position = -pivot
	$Components.position = -pivot

func toggle_build_mode():
	if $Camera3D.current:
		$BuildCamera.make_current()
		set_board_pivot(Vector3(w3.MAX_BOARD_WIDTH, 0.0, 0.0))
		
	else:
		var mc = get_mass_center()
		set_board_pivot(Vector3(mc.x * 2.0, 0.0, -mc.y * 2.0))
		set_board_pivot(Vector3(w3.MAX_BOARD_WIDTH, 0.0, 0.0))
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
	#var window_size = get_window().get_viewport().size

	#const SHIP_MARGIN := 0.1

	#var is_highest_x_in_frustum:bool = $Camera3D.unproject_position(highest_x).x > window_size.x + SHIP_MARGIN * window_size.x
	#var is_lowest_x_in_frustum:bool = $Camera3D.unproject_position(lowest_x).x < SHIP_MARGIN * window_size.x;
	#var is_highest_y_in_frustum:bool = $Camera3D.unproject_position(highest_y).y > window_size.y - SHIP_MARGIN * window_size.y 
	#var is_lowest_y_in_frustum:bool = $Camera3D.unproject_position(lowest_y).y < SHIP_MARGIN * window_size.y
	
	#var bot_speed = $Camera3D.unproject_position(highest_y).y - (window_size.y - SHIP_MARGIN * window_size.y)
	#var top_speed = SHIP_MARGIN * window_size.y - $Camera3D.unproject_position(lowest_y).y

	
	#if is_lowest_x_in_frustum and is_highest_x_in_frustum:
#		$Camera3D.position += Vector3(0, 0, 10.0 * delta).rotated(Vector3(1, 0, 0), $Camera3D.rotation.x)
#	elif is_highest_x_in_frustum:
#		$Camera3D.position.x += 10.0 * delta
#	elif is_lowest_x_in_frustum:
#		$Camera3D.position.x -= 10.0 * delta
		
#	if is_lowest_y_in_frustum and is_highest_y_in_frustum:
#		$Camera3D.position += Vector3(0, 0, 10.0 * delta).rotated(Vector3(1, 0, 0), $Camera3D.rotation.x)
#	elif is_highest_y_in_frustum:
#		if bot_speed > 3.0:
#			$Camera3D.position.z += 10.0 * delta
#	elif is_lowest_y_in_frustum:
#		if top_speed > 3.0:
#			$Camera3D.position.z -= 10.0 * delta

	$Camera3D.position.x = 0#center.x

func clear_children(parent):
	for child in parent.get_children():
		child.queue_free()
		parent.remove_child(child)

func load_from_account(key):
	exploding = false
	$Control.visible = true
	
	clear_children($pieces)
	clear_children($Components)
	
	previous_position = Vector2(0.0, 0.0)
	previous_rotation = 0.0
	
	estimated_rocket_force = Vector2(0.0, 0.0)
	estimated_rotational_force = 0.0
	
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
	max_health = account_data[32]
	$ProgressBar.max_value = max_health
	previous_health = max_health
	$ProgressBar.value = previous_health
	velocity = speed_from_byte(account_data[34])
	
	const ARRAY_START = 67
	
	for x in range(w3.MAX_BOARD_WIDTH):
		for y in range(w3.MAX_BOARD_HEIGHT):
			set_piece(Vector2i(x, y), account_data[ARRAY_START + (y * w3.MAX_BOARD_WIDTH + x) * w3.DATA_SIZE_PER_UNIT])
			pcb_meta[y * w3.MAX_BOARD_WIDTH + x] = account_data[ARRAY_START + (y * w3.MAX_BOARD_WIDTH + x) * w3.DATA_SIZE_PER_UNIT + 2]

	var mc = get_mass_center()
	set_board_pivot(Vector3(mc.x * 2.0, 0.0, -mc.y * 2.0))
	position = Vector3(account_data.decode_double(35), 0.0, account_data.decode_double(43))
	rotation.y = account_data.decode_double(51)
	adjust_camera(0.0)

func set_component_meta(pos: Vector2i, new_meta):
	pcb_meta[(pos.y * w3.MAX_BOARD_WIDTH + pos.x)] = new_meta

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
		piece.connect("meta_changed", Callable(self, "set_component_meta"))
		
	
	pcb_array[pos.y * w3.MAX_BOARD_WIDTH + pos.x] = type
	

func explode():
	if exploding:
		return
	var piece_size = $pieces.get_child_count()
	explode_velocities_piece.resize(piece_size)
	explode_rotations_piece.resize(piece_size)
	for i in range(piece_size):
		explode_velocities_piece[i] = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		explode_rotations_piece[i] = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	
	var component_size = $Components.get_child_count()
	explode_velocities_component.resize(component_size)
	explode_rotations_component.resize(component_size)
	for i in range(component_size):
		explode_velocities_component[i] = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		explode_rotations_component[i] = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))

	exploding = true
	$DeathTimer.start()


func _ready():
	$BuildCamera.size *= 10.0
	#$BuildCamera.position.x = MAX_BOARD_WIDTH
	pcb_array.resize(w3.MAX_BOARD_WIDTH * w3.MAX_BOARD_HEIGHT)
	pcb_meta.resize(w3.MAX_BOARD_WIDTH * w3.MAX_BOARD_HEIGHT)
	#SolanaClient.set_url("http://127.0.0.1:8899")
	#SolanaClient.set_encoding("base64")

	#load_from_account("2cn9FooLHGBNNDntbgxUW12YMQcpYMVgWBN1yJiTVhoP")
	#set_pcb_marker(Vector2i(0, 0))
	#set_pcb_marker(Vector2i(0, 1))
	#set_pcb_marker(Vector2i(0, 2))
	#activate_ghost_pcb()
	#activate_edge_pcb()
	#toggle_build_mode()


func _process(delta):
	var vel = get_velocity()

	#$pieces.rotation.y -= vel.x * 0.1 * delta
	#$Components.rotation.y = $pieces.rotation.y
	
	#position.x -= sin(rotation.y) * vel.y * 5.9 * delta
	#position.z -= cos(rotation.y) * vel.y * 5.9 * delta
	
	#position.z = $pieces.position.z
	#$pieces.transform()

	if exploding:
		var index = 0
		for child in $pieces.get_children():
			child.rotation += explode_rotations_piece[index] * delta
			child.position += explode_velocities_piece[index] * delta
			index += 1
			
		index = 0
		for child in $Components.get_children():
			child.rotation += explode_rotations_component[index] * delta
			child.position += explode_velocities_component[index] * delta
			index += 1
		#rotation.y -= vel.x * 0.5 * delta
		#$Components.rotation.y = $pieces.rotation.y
		#explode(explode_amount)
		#explode_amount += 0.08
	else:
		#adjust_camera(delta)
		
		position += Vector3(estimated_rocket_force.x, 0.0, estimated_rocket_force.y) * delta
		rotation.y -= estimated_rotational_force * delta

func _input(event):
	if event.is_action_pressed("ui_accept"):
		explode()

func _on_cursor_cursor_changed(coordinate):
	if $pcb_ghosts.is_position_marked(coordinate):
		$Cursor.set_snap(true)
	else:
		$Cursor.set_snap(false)


func _on_sync_timer_timeout():
	var data: PackedByteArray = w3.get_synced_data()
	
	var x = data.decode_double(35)
	var y = data.decode_double(43)
	var angle = data.decode_double(51)
	
	var timestamp = data.decode_s64(59)
	const TIME_UNTIL_PRESENTS := 121 
	if timestamp - previous_timestamp > TIME_UNTIL_PRESENTS:
		
		var owner: PackedByteArray = data.slice(0, 32)
		emit_signal("place_rewards", timestamp / TIME_UNTIL_PRESENTS, owner)
	
	if previous_position == Vector2(0.0, 0.0) and previous_rotation == 0.0:
		previous_position = Vector2(x, y)
		previous_rotation = angle
		
		estimated_rotational_force = (angle - rotation.y) / $SyncTimer.wait_time
		estimated_rocket_force = (Vector2(x, y) - Vector2(position.x, position.y)) / $SyncTimer.wait_time
		previous_health = data[32]
	else:
		estimated_rotational_force = (angle - previous_rotation) / $SyncTimer.wait_time
		estimated_rocket_force = (Vector2(x, y) - previous_position) / $SyncTimer.wait_time
		
		previous_position = Vector2(x, y)
		previous_rotation = angle
		
		if(estimated_rocket_force.length_squared() > 0.001):
			$Control.visible = false
		
		if previous_health != data[32]:
			previous_health = data[32]
			$ProgressBar.value = previous_health
			emit_signal("enemy_needs_revive")
			
		
	print("x should be: ", data.decode_double(35))
	print("y should be: ", data.decode_double(43))
	print("angle should be: ", data.decode_double(51))
	print("health should be: ", data[32])
	if data[32] == 0:
		explode()


func _on_death_timer_timeout():
	emit_signal("needs_respawn")
