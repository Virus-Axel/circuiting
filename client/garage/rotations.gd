extends Node3D

const ROTATION_SPEED := 0.3
@onready var rot: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	rot = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * ROTATION_SPEED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	rotation += rot * delta
	#print(rot)
	pass
