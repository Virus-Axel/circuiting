extends Node3D


const RANGE = 0.4
const ANIMATION_TIME = 1.0
const SLEEP_TIME = 0.5
var animation_time = 0.0
var direction: float

var activation_requested = false
var activation_time = 0.0

var enemy_ref

const SCALE_INDICATION := 0.2
const SCALE_FREQUENCY := 5.0

signal meta_changed(grid_pos, new_data)

func notify_activation():
	activation_requested = true
	activation_time = 0.0
	print("trying to activate gun")
	
func confirm_activation():
	print("gun activation confirmed")
	
func finalize_activation():
	$component.scale = Vector3(1.0, 1.0, 1.0)
	$GunShot.play()
	activation_time = 0.0
	activation_requested = false
	rotation.y = -PI/2.0
	w3.emit_signal("shots_fired")
	$component.get_node("AnimationPlayer").play("shoot")
	$CSGCylinder3D.fire()
	
func abort_activation():
	activation_time = 0.0
	activation_requested = false
	$component.scale = Vector3(1.0, 1.0, 1.0)
	print("Engine activation failed")

func activate():
	$ClickSound.play()
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

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_time = randf_range(0.0, ANIMATION_TIME * 2 + SLEEP_TIME * 2)
	direction = randf()*PI*2.0
	rotation.y = direction
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	animation_time += delta
	if animation_time < ANIMATION_TIME:
		rotation.y = direction + RANGE * animation_time
	elif animation_time > ANIMATION_TIME * 2 + 2 * SLEEP_TIME:
		animation_time = 0.0
	elif animation_time > ANIMATION_TIME * 2 + SLEEP_TIME:
		pass
	elif animation_time > ANIMATION_TIME + SLEEP_TIME:
		rotation.y = direction + RANGE * (1.0 - (animation_time - ANIMATION_TIME - SLEEP_TIME))
	
	if activation_requested:
		$component.scale = Vector3(1.0, 1.0, 1.0) +  Vector3(SCALE_INDICATION, SCALE_INDICATION, SCALE_INDICATION) * sin(activation_time * SCALE_FREQUENCY)
		activation_time += delta
	
	pass
