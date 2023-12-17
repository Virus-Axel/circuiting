extends Node3D

var presents = []

func kill_enemy():
	$Enemies/Enemy01.die()

# Called when the node enters the scene tree for the first time.
func _ready():
	presents.resize(31)
	#w3.play_account = 
	#w3.play_keypair = Pubkey.new_from_string("EWhQiSu9E3EPQdMC1FmF25Q2FnybTSnFJ4Gby8hG5qCA")
	#$Ship.load_from_account(w3.play_account.get_public_value())
	$Ship.load_from_account("6rZc4SHqg7u2S4VfbW2ATTVnA4njFzSrdTQr8J8F9SNi")
	$Enemies/Enemy01.hunt($Ship)
	w3.shots_fired.connect(Callable(self, "kill_enemy"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_sync_timer_timeout():
	var data: PackedByteArray = w3.get_synced_data()
	print("x should be: ", data.decode_double(35))
	print("y should be: ", data.decode_double(43))
	print("angle should be: ", data.decode_double(51))


func _on_ship_needs_respawn():
	var tx = w3.claim_reward_and_respawn()
	Environment
	var MAX_RETRIES = 20
	for i in range(MAX_RETRIES):
		if tx.is_finalized():
			$Ship.load_from_account(w3.play_account.get_public_value())
			$Enemies/Enemy01.die()
			return
		else:
			await get_tree().create_timer(1.0).timeout
	
	print("errorr")


func _on_ship_place_rewards(time, key):
	const MAX_LENGTH := 100.0
	var present_resource = preload("res://present/present.tscn")
	for i in range(key.size() - 1):
		if presents[i] != null:
			presents[i].queue_free()
			remove_child(presents[i])

		var present_pos = Vector3(float((key[i] + time) % 256) / 255.0 - 0.5, 0.0, float((key[i+1] + time) % 256) / 255.0 - 0.5) * 2.0 * MAX_LENGTH;
		var present = present_resource.instantiate().duplicate()
		present.player_ref = $Ship
		present.connect("should_claim", Callable(self, "claim_score"))
		present.position = present_pos
		add_child(present)
		presents[i] = present
		

func claim_score():
	var tx = w3.claim_score()
	for i in range(10):
		if tx.is_confirmed():
			$Ship.score += 1
			$Score.text = str($Ship.score)
	pass
