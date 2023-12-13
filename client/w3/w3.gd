extends Node

const PID := "2DzKRbWVuGgwiX4rAxQLbR5QzszGcmoKgSp7C1awzFsi"
const SYSTEM_PID := "11111111111111111111111111111111"
@onready var main_signer = $PhantomController

const DEFAULT_LAMPORTS_PER_BYTE_YEAR: int = 1000000000 / 100 * 365 / (1024 * 1024)
const ACCOUNT_STORAGE_OVERHEAD: int = 128
const DEFAULT_EXEMPTION_THRESHOLD: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	#SolanaClient.set_url("https://api.testnet.solana.com");
	SolanaClient.set_url("http://127.0.0.1:8899");
	SolanaClient.set_encoding("base64")
	
	$PhantomController.connect_phantom()
	await $PhantomController.connection_established
	print(SolanaSDK.bs58_encode($PhantomController.get_connected_key()))



func create_spaceship_transaction():
	var tx = Transaction.new()
	tx.set_payer(main_signer)
	var instruction = Instruction.new()
	
	# ID
	instruction.program_id = Pubkey.new_from_string(PID)
	
	# Accounts
	var accounts := []
	accounts.push_back(new_account_meta(main_signer, true, true))
	
	var kp = get_derived_keypair()
	accounts.push_back(new_account_meta(kp, true, true))

	instruction.set_accounts(accounts)

	# Data
	var data := PackedByteArray([0])
	instruction.set_data(data)
	
	const DATA_SIZE = 24643
	
	#tx.add_instruction(SystemProgram.create_account(main_signer, kp, minimum_balance_to_rent_extemption(24643), 24643, Pubkey.new_from_string(PID)))
	tx.add_instruction(instruction)
	
	print(tx.serialize())
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	print(await tx.transaction_response)


func send_commit_transaction(actions: Array):
	var tx = Transaction.new()
	tx.set_payer(main_signer)
	
	for action in actions:
		var instruction = Instruction.new()
		
		# ID
		instruction.program_id = Pubkey.new_from_string(PID)
		
		# Accounts
		var accounts := []
		accounts.push_back(new_account_meta(main_signer, true, true))
		
		var kp = get_derived_keypair()
		accounts.push_back(new_account_meta(kp, true, true))

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
	print(await tx.transaction_response)

func get_derived_keypair() -> Keypair:
	return Keypair.new_from_seed(Pubkey.new_from_string(PID).get_bytes())


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

