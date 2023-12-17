extends Node3D

const ROTATION_SPEED := 0.8
var player_ref

signal should_claim

var fade_time := 0.0
var fading := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func fade():
	fading = true
	fade_time = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$CSGBox3D.rotation.x += ROTATION_SPEED * delta
	$CSGBox3D.rotation.y += ROTATION_SPEED * 2.0 * delta
	$CSGBox3D.rotation.z += ROTATION_SPEED * 3.0 * delta
	
	$CSGBox3D2.rotation.y += ROTATION_SPEED * delta
	$CSGBox3D2.rotation.z += ROTATION_SPEED * 2.0 * delta
	$CSGBox3D2.rotation.x += ROTATION_SPEED * 3.0 * delta
	
	$CSGBox3D3.rotation.z += ROTATION_SPEED * delta
	$CSGBox3D3.rotation.x += ROTATION_SPEED * 2.0 * delta
	$CSGBox3D3.rotation.y += ROTATION_SPEED * 3.0 * delta
	
	if visible and not fading and (player_ref.position - position).length() < 5.0:
		emit_signal("should_claim")
		fade()
		
	if fading:
		const FADE_SPEED := 1.1
		scale += Vector3(1.0, 1.0, 1.0) * FADE_SPEED * fade_time * 0.1
		$CSGBox3D.material.albedo_color.a = max(0.0, 1.0 - fade_time * FADE_SPEED )
		$CSGBox3D2.material.albedo_color.a = max(0.0, 1.0 - fade_time * FADE_SPEED )
		$CSGBox3D3.material.albedo_color.a = max(0.0, 1.0 - fade_time * FADE_SPEED )
		fade_time += delta
		if fade_time * FADE_SPEED > 1.0:
			visible = false
			$CSGBox3D.material.albedo_color.a = 0.3
			$CSGBox3D2.material.albedo_color.a = 0.3
			$CSGBox3D3.material.albedo_color.a = 0.3
			fading = false
			fade_time = 0.0
		
	pass
