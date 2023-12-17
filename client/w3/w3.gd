extends Node

const PID := "J3hetoaLkMgw9fSp8BpvP2KDfuABnMp9fFzFPAa4E7QT"
const SYSTEM_PID := "11111111111111111111111111111111"
@onready var main_signer = $PhantomController
var play_keypair: Keypair
var play_account: Keypair
var are_keys_derived := false

const DEFAULT_LAMPORTS_PER_BYTE_YEAR: int = int(1000000000 / 100) * 365 / (1024 * 1024)
const ACCOUNT_STORAGE_OVERHEAD: int = 128
const DEFAULT_EXEMPTION_THRESHOLD: float = 2.0
const MAX_BOARD_HEIGHT = 32
const MAX_BOARD_WIDTH = 16
const DATA_SIZE_PER_UNIT = 3

signal play_key_derived(keypair, account)
signal shots_fired

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
	SolanaClient.set_url("https://api.testnet.solana.com");
	#SolanaClient.set_url("http://127.0.0.1:8899");
	SolanaClient.set_encoding("base64")
	
	$PhantomController.connect_phantom()
	await $PhantomController.connection_established
	print(SolanaSDK.bs58_encode($PhantomController.get_connected_key()))
	
	#$tokens.create_token_accounts()

func await_signature_finalized(signature: String):
	const MAX_RETRIES = 20
	for i in range(MAX_RETRIES):
		var rpc_result = SolanaClient.get_signature_statuses([signature], false)
		if rpc_result.has("result"):
			var value = rpc_result["result"]["value"][0]
			if value != null:
				
				if value["confirmationStatus"] == "finalized":
					return true
		await get_tree().create_timer(1.0).timeout
		
	return false

func request_ardrop(account_string, amount):
	var rpc_result = SolanaClient.request_airdrop(account_string, amount)
	
	if rpc_result.has("result"):
		return rpc_result["result"]
	else:
		return ""


func fund_broke_accounts():
	var rpc_result = SolanaClient.get_balance(w3.play_keypair.get_public_value())
	
	var sig1: String = ""
	var sig3: String = ""
	
	if rpc_result.has("result"):
		if rpc_result["result"]["value"] < 500000000:
			sig1 = request_ardrop(w3.play_keypair.get_public_value(), 1000000000)
	
	#rpc_result = SolanaClient.get_balance(w3.play_account.get_public_value())

	#if rpc_result.has("result"):
	#	if rpc_result["result"]["value"] < 1000000000:
	#		sig2 = request_ardrop(w3.play_account.get_public_value(), 1000000000)

	rpc_result = SolanaClient.get_balance(SolanaSDK.bs58_encode(main_signer.get_connected_key()))

	if rpc_result.has("result"):
		if rpc_result["result"]["value"] < 500000000:
			sig3 = request_ardrop(SolanaSDK.bs58_encode(main_signer.get_connected_key()), 1000000000)


	if not sig1.is_empty():
		await await_signature_finalized(sig1)

	#if not sig2.is_empty():
	#	await await_signature_finalized(sig2)
	
	if not sig3.is_empty():
		await await_signature_finalized(sig3)
	
	print("Funding done")
	

func load_play_keypair():
	var message_to_sign := "Note, this game interacts with solana. You may lose every assets earned in game."
	
	$PhantomController.sign_text_message(message_to_sign)
	var signature = await $PhantomController.message_signed
	
	# Two secret keypairs
	play_keypair = Keypair.new_from_seed(signature)
	play_account = Keypair.new_from_seed(play_keypair.get_private_bytes())
	
	does_account_exist(play_account.get_public_value())
	
	are_keys_derived = true
	
	await fund_broke_accounts()
	$tokens.create_token_accounts()

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
	#accounts.push_back(new_account_meta(play_keypair, true, false))

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([0])
	instruction.set_data(data)

	
	#tx.add_instruction(SystemProgram.create_account(main_signer, play_account, minimum_balance_to_rent_extemption(DATA_SIZE), DATA_SIZE, Pubkey.new_from_string(PID)))
	tx.add_instruction(instruction)
	
	print(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	
	return tx


func activate_component_transaction(pos: Vector2i):
	var tx = Transaction.new()
	tx.set_payer(play_keypair)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(play_keypair, true, true))
	accounts.push_back(new_account_meta(play_account, true, true))

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([3, pos.x, pos.y])
	instruction.set_data(data)
	
	tx.add_instruction(instruction)
	
	print(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	
	return tx

func get_synced_data():
	var tx = Transaction.new()
	tx.set_payer(play_keypair)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(play_keypair, true, true))
	accounts.push_back(new_account_meta(play_account, true, true))

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([100])
	instruction.set_data(data)
	
	tx.add_instruction(instruction)
	
	var encoded_tx = SolanaSDK.bs64_encode(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign()
	var sim_result = SolanaClient.simulate_transaction(encoded_tx, false, true,[play_account.get_public_value()], "base64")
	#print(sim_result)
	if sim_result.has("result"):
		if sim_result["result"].has("value"):
			var sim_value = sim_result["result"]["value"]
			if sim_value["accounts"].size() > 0:
				return SolanaSDK.bs64_decode(sim_value["accounts"][0]["data"][0])
	
	return []

func claim_reward_and_respawn():
	var tx = Transaction.new()
	tx.set_payer(play_keypair)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(play_keypair, true, true))
	accounts.push_back(new_account_meta(play_account, true, true))

	accounts.push_back(new_account_meta($tokens.get_board_mint(), false, true))
	accounts.push_back(new_account_meta($tokens.get_engine_mint(), false, true))
	accounts.push_back(new_account_meta($tokens.get_gun_mint(), false, true))
	
	accounts.push_back(new_account_meta($tokens.get_board_token_account(), false, true))
	accounts.push_back(new_account_meta($tokens.get_engine_token_account(), false, true))
	accounts.push_back(new_account_meta($tokens.get_gun_token_account(), false, true))

	accounts.push_back(new_account_meta($tokens.get_authority(), false, false))
	
	accounts.push_back(new_account_meta(Pubkey.new_from_string("SysvarRent111111111111111111111111111111111"), false, false))
	accounts.push_back(new_account_meta(Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), false, false))
	

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([10])
	instruction.set_data(data)
	
	tx.add_instruction(instruction)
	
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
		accounts.push_back(new_account_meta(play_account, true, true))
		
		if action[1] == 1:
			accounts.push_back(new_account_meta($tokens.get_board_mint(), false, true))
			accounts.push_back(new_account_meta($tokens.get_board_token_account(), false, true))
		if action[1] == 2:
			accounts.push_back(new_account_meta($tokens.get_gun_mint(), false, true))
			accounts.push_back(new_account_meta($tokens.get_gun_token_account(), false, true))
		if action[1] == 3:
			accounts.push_back(new_account_meta($tokens.get_engine_mint(), false, true))
			accounts.push_back(new_account_meta($tokens.get_engine_token_account(), false, true))

		accounts.push_back(new_account_meta($tokens.get_authority(), false, false))
		
		accounts.push_back(new_account_meta(Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), false, false))

		instruction.set_accounts(accounts)

		# Data
		var data := PackedByteArray([1, action[0].x, action[0].y, action[1]])
		instruction.set_data(data)
		
		tx.add_instruction(instruction)
	
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

func claim_score():
	var tx = Transaction.new()
	tx.set_payer(play_keypair)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(play_keypair, true, true))
	accounts.push_back(new_account_meta(play_account, true, true))

	accounts.push_back(new_account_meta($tokens.get_score_mint(), false, true))
	accounts.push_back(new_account_meta($tokens.get_score_token_account(), false, true))

	accounts.push_back(new_account_meta($tokens.get_authority(), false, false))
	
	accounts.push_back(new_account_meta(Pubkey.new_from_string("SysvarRent111111111111111111111111111111111"), false, false))
	accounts.push_back(new_account_meta(Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), false, false))
	

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([11])
	instruction.set_data(data)
	
	tx.add_instruction(instruction)
	
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	
	return tx
