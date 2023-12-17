extends Node3D

var engine_mode = 0
var activation_requested = false
var activation_time = 0.0

const SCALE_INDICATION := 0.2
const SCALE_FREQUENCY := 5.0

signal meta_changed(grid_pos, new_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	stop_fire()
	pass # Replace with function body.

func notify_activation():
	activation_requested = true
	activation_time = 0.0
	print("trying to activate engine")
	
func confirm_activation():
	print("Engine activation confirmed")

func start_fire():
	$jet_01.get_node("Cone").visible = true
	$jet_01.get_node("Cone_001").visible = true

func stop_fire():
	$jet_01.get_node("Cone").visible = false
	$jet_01.get_node("Cone_001").visible = false

func finalize_activation():
	activation_time = 0.0
	activation_requested = false
	if engine_mode == 1:
		engine_mode = 0
		stop_fire()
	else:
		engine_mode = 1
		start_fire()
		$jet_01.get_node("AnimationPlayer").play("ConeAction")
		
	print("Engine activation complete")
	emit_signal("meta_changed", Vector2i(position.x, -position.z) / 2, engine_mode)
	
func abort_activation():
	activation_time = 0.0
	activation_requested = false
	$jet_01.scale = Vector3(1.0, 1.0, 1.0)
	print("Engine activation failed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if activation_requested:
		$jet_01.scale = Vector3(1.0, 1.0, 1.0) +  Vector3(SCALE_INDICATION, SCALE_INDICATION, SCALE_INDICATION) * sin(activation_time * SCALE_FREQUENCY)
		activation_time += delta
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
