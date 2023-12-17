extends Control


func _ready():
	w3.connect("play_key_derived", Callable(self, "keys_derived"))
	pass

func _process(delta):
	pass

func keys_derived(play_key, play_acc):
	print(play_key.get_public_value())
	print(play_acc.get_public_value())

func _on_button_pressed():
	if not w3.are_keys_derived:
		w3.load_play_keypair()
		await w3.play_key_derived
	
	await w3.fund_broke_accounts()
	
	if not w3.does_account_exist(w3.play_account.get_public_value()):
		var tx: Transaction = w3.create_spaceship_transaction()
		while(not tx.is_confirmed()):
			print("loading")
			await await get_tree().create_timer(0.5).timeout
	else:
		print("account exists")
		#var tx = w3.create_spaceship_transaction()
		#while not tx.is_finalized():
		#	print("waiting for data cleanup")
	#		await get_tree().create_timer(1.0).timeout
		
	get_tree().change_scene_to_file("res://garage/garage.tscn")

