extends Node3D


const RANGE = 0.4
const ANIMATION_TIME = 1.0
const SLEEP_TIME = 0.5
var animation_time = 0.0
var direction: float

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
	
	pass
