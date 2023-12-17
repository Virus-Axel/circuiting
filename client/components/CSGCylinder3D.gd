extends CSGCylinder3D

const LASER_THICKNES := 0.1

func fire():
	visible = true
	$Timer.start()
	
func _process(delta):
	if $Timer.is_stopped():
		return
	else:
		print($Timer.wait_time - $Timer.time_left)
		#var scale_value = $Timer.wait_time - $Timer.time_left
		var scale_value := 0.0
		var tick_time = $Timer.wait_time - $Timer.time_left
		if $Timer.time_left > ($Timer.wait_time / 2.0):		
			scale_value = smoothstep(0.001, $Timer.wait_time / 2.0, tick_time)
		else:
			scale_value = smoothstep($Timer.wait_time / 2.0, 0.001, tick_time - $Timer.wait_time / 2.0)
		scale.x = scale_value * LASER_THICKNES
		scale.z = scale_value * LASER_THICKNES
		


func _on_timer_timeout():
	visible = false
	pass # Replace with function body.
