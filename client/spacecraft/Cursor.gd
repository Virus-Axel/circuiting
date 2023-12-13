extends Node3D


var dragging = false
var cursor_mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func enable():
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func disable():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	if event is InputEventMouseMotion and dragging:
		var window_size = get_window().get_viewport().size
		#var new_pos = Vector3(event.position.x / window_size.x, 0.0, event.position.y / window_size.y) * $"../BuildCamera".size * 2.0
		var new_pos = get_window().get_camera_3d().project_position(event.position, 1.0)
		print(new_pos)

		#cursor_mesh.position = $"../BuildCamera".position + new_pos - Vector3($"../BuildCamera".size, 0.0, $"../BuildCamera".size)
		cursor_mesh.position = new_pos
		print(cursor_mesh.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_grab_component(mesh):
	cursor_mesh = mesh
	add_child(cursor_mesh)
	dragging = true
	enable()
	pass # Replace with function body.
