extends Node3D


var ref_screen := Vector2()
var ref_world := Vector3()

var dragging = false
var grabbing = false
var cursor_mesh
var component_type

var hovered_grid_coord: Vector2i

signal cursor_changed(coordinate)
signal placed_component(pos, type)
signal disabled

var snap = false

func set_snap(should_snap):
	snap = should_snap

func _ready():
	pass # Replace with function body.


func enable():
	visible = true
	#process_mode = Node.PROCESS_MODE_ALWAYS

func disable():
	visible = false
	if get_child_count() > 0:
		var child = get_children()[0]
		child.queue_free()
		remove_child(child)
		
	emit_signal("disabled")
	#process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			dragging = true
			grabbing = false
			ref_screen = event.position
			ref_world = $"../BuildCamera".position
		else:
			dragging = false
			grabbing = false
			if(snap and visible):
				emit_signal("placed_component", Vector2i(hovered_grid_coord.x + w3.MAX_BOARD_WIDTH / 2, hovered_grid_coord.y), component_type)

			disable()
	
	if event is InputEventMouseMotion and dragging:
		var diff_screen: Vector2 = event.position - ref_screen
		$"../BuildCamera".position = ref_world - Vector3(diff_screen.x / 50.0, 0.0, diff_screen.y / 50.0)
	
	if event is InputEventMouseMotion and grabbing:
		var window_size = get_window().get_viewport().size
		#var new_pos = Vector3(event.position.x / window_size.x, 0.0, event.position.y / window_size.y) * $"../BuildCamera".size * 2.0
		var new_pos = get_window().get_camera_3d().project_position(event.position, 1.0)

		#cursor_mesh.position = $"../BuildCamera".position + new_pos - Vector3($"../BuildCamera".size, 0.0, $"../BuildCamera".size)
		if hovered_grid_coord != Vector2i(round(new_pos.x / 2.0), -round(new_pos.z / 2.0)):
			hovered_grid_coord = Vector2i(round(new_pos.x / 2.0), -round(new_pos.z / 2.0))

			emit_signal("cursor_changed", hovered_grid_coord)
		
		if snap:
			cursor_mesh.position = Vector3(hovered_grid_coord.x * 2.0, 5.0, -hovered_grid_coord.y * 2.0)
		else:
			cursor_mesh.position = new_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_grab_component(mesh, type):
	cursor_mesh = mesh
	component_type = type
	add_child(cursor_mesh)
	grabbing = true
	dragging = false
	enable()
	pass # Replace with function body.
