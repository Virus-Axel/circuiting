extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	#w3.play_account = 
	#w3.play_keypair = Pubkey.new_from_string("EWhQiSu9E3EPQdMC1FmF25Q2FnybTSnFJ4Gby8hG5qCA")
	#$Ship.load_from_account(w3.play_account.get_public_value())
	$Ship.load_from_account("6rZc4SHqg7u2S4VfbW2ATTVnA4njFzSrdTQr8J8F9SNi")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
