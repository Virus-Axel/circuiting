extends Node3D

const hover_radius := 5.0

var player_ref
var current_goal: Vector3
var start_pos: Vector3

var hunt_time := 2.0
var dead := true

func hunt(player):
	player_ref = player
	$update_goal_timer.start()


func _ready():
	#die()
	#revive()
	$enemy/Node3D.beam()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		return
	if(hunt_time > 1.0):
		pass
	else:
		position = lerp(start_pos, current_goal, hunt_time)
		hunt_time += delta
	
	var angle = Vector2(position.x, position.z).angle_to_point(Vector2(player_ref.position.x, player_ref.position.z))
	#$enemy.get_node("Armature/Skeleton3D/Sphere").rotation.y = PI / 2.0 -angle
	$enemy.rotation.y = PI / 2.0 -angle

func revive():
	if dead and $DeathTimer.is_stopped():
		dead = false
		$ReviveSound.play()
		$ShootTimer.start()
		$enemy.get_node("AnimationPlayer").play("ArmatureAction")

func die():
	if not dead:
		$DeathTimer.start()
		dead = true
		$ShootTimer.stop()
		$enemy.get_node("AnimationPlayer").play("death")

func set_new_goal():
	var random_vector = Vector3(1.0, 0.0, 0.0).rotated(Vector3(0.0, 1.0, 0.0), randf_range(-PI, PI)) * hover_radius
	
	start_pos = position
	hunt_time = 0.0
	const DISTANCE_TO_SHIP :=  10.0
	var view_add = Vector3(0.0, 0.0, -DISTANCE_TO_SHIP).rotated(Vector3(0.0, 1.0, 0.0), player_ref.rotation.y)
	view_add.y = 0.0
	current_goal = player_ref.position + random_vector + view_add * 2.0
	
	pass # Replace with function body.
