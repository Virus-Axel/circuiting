extends Node3D

func are_points_close_enough(point_a, point_b, threshold: float) -> bool:
	return (point_a - point_b).length() < threshold

func get_child_at_position(pos: Vector2i):
	for child in get_children():
		if are_points_close_enough(Vector2(pos.x * 2, -pos.y * 2), Vector2(child.position.x, child.position.z), 0.01):
			return child;
			
	return null;

func activate_component(pos: Vector2i):
	var child = get_child_at_position(pos)
	if child == null:
		return
	
	var tx: Transaction = w3.activate_component_transaction(pos)
	var finalized = false
	child.notify_activation()
	for i in range(20):
		if tx.is_finalized():
			child.finalize_activation()
			return
		elif tx.is_confirmed():
			child.confirm_activation()
			
		await get_tree().create_timer(1.0).timeout
	
	child.abort_activation()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
