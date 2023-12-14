extends Node

const PID := "2DzKRbWVuGgwiX4rAxQLbR5QzszGcmoKgSp7C1awzFsi"
const SYSTEM_PID := "11111111111111111111111111111111"
@onready var main_signer = $PhantomController
var play_keypair: Keypair
var play_account: Keypair
var are_keys_derived := false

const DEFAULT_LAMPORTS_PER_BYTE_YEAR: int = 1000000000 / 100 * 365 / (1024 * 1024)
const ACCOUNT_STORAGE_OVERHEAD: int = 128
const DEFAULT_EXEMPTION_THRESHOLD: float = 2.0
const MAX_BOARD_HEIGHT = 128
const MAX_BOARD_WIDTH = 64

signal play_key_derived(keypair, account)

func does_account_exist(acc):
	var rpc_result = SolanaClient.get_account_info(acc)
	if rpc_result.has("result"):
		if rpc_result["result"].has("value"):
			var val = rpc_result["result"]["value"]
			if val == null:
				return false
			else:
				print(val)
				return true
	
	return false
	

func _ready():
	#SolanaClient.set_url("https://api.testnet.solana.com");
	SolanaClient.set_url("http://127.0.0.1:8899");
	SolanaClient.set_encoding("base64")
	
	$PhantomController.connect_phantom()
	await $PhantomController.connection_established
	print(SolanaSDK.bs58_encode($PhantomController.get_connected_key()))


func load_play_keypair():
	var message_to_sign := "Note, this game interacts with solana. You may lose every assets earned in game."
	
	$PhantomController.sign_text_message(message_to_sign)
	var signature = await $PhantomController.message_signed
	
	# Two secret keypairs
	play_keypair = Keypair.new_from_seed(signature)
	play_account = Keypair.new_from_seed(play_keypair.get_private_bytes())
	
	does_account_exist(play_account.get_public_value())
	
	are_keys_derived = true
	emit_signal("play_key_derived", play_keypair, play_account)


func create_spaceship_transaction():
	var tx = Transaction.new()
	tx.set_payer(main_signer)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(main_signer, true, true))
	
	accounts.push_back(new_account_meta(play_account, true, true))
	accounts.push_back(new_account_meta(play_keypair, true, false))

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([0])
	instruction.set_data(data)
	
	const DATA_SIZE = 24643
	
	tx.add_instruction(SystemProgram.create_account(main_signer, play_account, minimum_balance_to_rent_extemption(24643), 24643, Pubkey.new_from_string(PID)))
	tx.add_instruction(instruction)
	
	print(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	
	return tx


func send_commit_transaction(actions: Array):
	var tx = Transaction.new()
	tx.set_payer(play_keypair)
	
	for action in actions:
		var instruction = Instruction.new()
		
		# ID
		instruction.program_id = Pubkey.new_from_string(PID)
		
		# Accounts
		var accounts := []
		accounts.push_back(new_account_meta(play_keypair, true, true))
		
		var kp = get_derived_keypair()
		accounts.push_back(new_account_meta(play_account, true, true))

		instruction.set_accounts(accounts)

		# Data
		var data := PackedByteArray([1, action[0].x, action[0].y, action[1]])
		instruction.set_data(data)
		
		const DATA_SIZE = 24643
		
		#tx.add_instruction(SystemProgram.create_account(main_signer, kp, minimum_balance_to_rent_extemption(24643), 24643, Pubkey.new_from_string(PID)))
		tx.add_instruction(instruction)
	
	print(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign_and_send()

	return tx

func get_derived_keypair() -> Keypair:
	#return Keypair.new_from_seed(Pubkey.new_from_string(PID).get_bytes())
	return play_keypair


func new_account_meta(key, signer, writable) -> AccountMeta:
	var meta = AccountMeta.new()
	meta.key = key
	meta.is_signer = signer
	meta.writeable = writable
	
	return meta


func minimum_balance_to_rent_extemption(data_size) -> int:
	return round(float((ACCOUNT_STORAGE_OVERHEAD + data_size) * DEFAULT_LAMPORTS_PER_BYTE_YEAR) * DEFAULT_EXEMPTION_THRESHOLD)


func _on_phantom_controller_signing_error():
	print("Phantom failed")
	pass # Replace with function body.

