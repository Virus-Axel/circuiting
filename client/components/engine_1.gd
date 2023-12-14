extends Node3D

var engine_mode = 0

signal meta_changed(grid_pos, new_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func notify_activation():
	print("trying to activate engine")
	
func confirm_activation():
	print("Engine activation confirmed")
	
func finalize_activation():
	if engine_mode == 1:
		engine_mode = 0
	else:
		engine_mode = 1
	print("Engine activation complete")
	emit_signal("meta_changed", Vector2i(position.x, -position.z) / 2, engine_mode)
	
func abort_activation():
	print("Engine activation failed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func activate():
	var tx: Transaction = w3.activate_component_transaction(Vector2i(position.x, -position.y) / 2)
	var finalized = false
	notify_activation()
	for i in range(20):
		if tx.is_finalized():
			finalize_activation()
			return
		elif tx.is_confirmed():
			confirm_activation()
			
		await get_tree().create_timer(1.0).timeout
	
	abort_activation()

func _on_static_body_3d_input_event(camera, event, position, normal, shape_idx):
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		print("clicked")
		print(self.position)
		activate()
