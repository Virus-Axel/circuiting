extends Node3D


const MOTION_DISTANCE = 0.5
const ANIMATION_TIME = 1.0
var time = 0.0

func are_points_close_enough(point_a, point_b, threshold: float) -> bool:
	return (point_a - point_b).length() < threshold
	

func is_position_marked(pos: Vector2i):
	for child in get_children():
		if are_points_close_enough(Vector2(pos * 2), child.position, 0.01):
			return true;
			
	return false;

func clear_markers():
	for child in get_children():
		child.queue_free()
		remove_child(child)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time = delta
	var distance = MOTION_DISTANCE - position.z
	
	pass
