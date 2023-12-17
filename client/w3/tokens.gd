extends Node

const SCORE_TOKEN: String = "AHPdurs9gpCQAj3AhkAoGijnRbwTCB6Te7EMZouQUBuz"
const BOARD_TOKEN: String = "37qvnL6sANz4CSFgwXbW7veDMKHbS8myrgV2jSPsjkqG"
const ENGINE_TOKEN: String = "D8CBcbrNrve4re82XyqdjoGB9vXgK3f4ZQm4doNx3ADr"
const GUN_TOKEN: String = "EXDpF9FDD39TAe79ihD8Nhik2wUoDAZ3s7DAhJPwiYiW"

const AUTHORITY_SEED: String = "CIRCUITING_AUTHORITY_SEED"

func create_token():
	var tx = Transaction.new()
	tx.set_payer(w3.main_signer)
	
	var mint_signer: Keypair = Keypair.new_random()
	print("Creating mint: ", mint_signer.get_public_value())
	var mint_authority:Pubkey = Pubkey.new_pda([AUTHORITY_SEED], Pubkey.new_from_string(w3.PID))
	
	print(mint_authority.get_value())
		
	tx.add_instruction(SystemProgram.create_account(w3.main_signer, mint_signer, 4593600, 82, Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")))
	tx.add_instruction(TokenProgram.initialize_mint(mint_signer, mint_authority, null, 0))
	#tx.add_instruction(instruction)
	
	tx.update_latest_blockhash("")
	tx.sign_and_send()
	print(await tx.transaction_response)
	
	return tx

func get_score_mint():
	return Pubkey.new_from_string(SCORE_TOKEN)

func get_board_mint():
	return Pubkey.new_from_string(BOARD_TOKEN)
	
func get_engine_mint():
	return Pubkey.new_from_string(ENGINE_TOKEN)
	
func get_gun_mint():
	return Pubkey.new_from_string(GUN_TOKEN)

func get_score_token_account():
	return Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(SCORE_TOKEN))

func get_board_token_account():
	return Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(BOARD_TOKEN))

func get_gun_token_account():
	return Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(GUN_TOKEN))

func get_engine_token_account():
	return Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(ENGINE_TOKEN))

func get_authority():
	return Pubkey.new_pda([AUTHORITY_SEED], Pubkey.new_from_string(w3.PID))


func create_token_accounts():
	var token_program = Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
	
	var score_ata: Pubkey = Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(SCORE_TOKEN))
	var board_ata: Pubkey = Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(BOARD_TOKEN))
	var engine_ata: Pubkey = Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(ENGINE_TOKEN))
	var gun_ata: Pubkey = Pubkey.new_associated_token_address(w3.play_keypair, Pubkey.new_from_string(GUN_TOKEN))
	
	var tx = Transaction.new()
	tx.set_payer(w3.play_keypair)

	var do_something = false
	
	if not w3.does_account_exist(score_ata.get_value()):
		do_something = true
		tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(SCORE_TOKEN), token_program))
	if not w3.does_account_exist(board_ata.get_value()):
		do_something = true
		tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(BOARD_TOKEN), token_program))
	if not w3.does_account_exist(engine_ata.get_value()):
		do_something = true
		tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(ENGINE_TOKEN), token_program))
	if not w3.does_account_exist(gun_ata.get_value()):
		do_something = true
		tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(GUN_TOKEN), token_program))

	if not do_something:
		print("TOKEN ACCS already done")
		return
	else:
		print("SOME TOKEN ACCS NEEDS TO BE CREATED")

	tx.update_latest_blockhash("")
	tx.sign_and_send()
	
	return tx

func create_token_metadata():
	var token_program = Pubkey.new_from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
	
	var board_ata: Pubkey = get_board_token_account()
	var engine_ata: Pubkey = get_engine_token_account()
	var gun_ata: Pubkey = get_gun_token_account()
	
	var board_mint: Pubkey = get_board_mint()
	var engine_mint: Pubkey = get_engine_mint()
	var gun_mint: Pubkey = get_gun_mint()
	
	var auth = get_authority()
	
	var tx = Transaction.new()
	tx.set_payer(w3.play_keypair)
	
	var md := load("res://w3/board_meta.tres")

	tx.add_instruction(MplTokenMetadata.create_metadata_account(board_ata, board_mint, auth, w3.play_keypair, auth, md, false, 0))
	#tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(ENGINE_TOKEN), token_program))
	#tx.add_instruction(AssociatedTokenAccountProgram.create_associated_token_account(w3.play_keypair, w3.play_keypair, Pubkey.new_from_string(GUN_TOKEN), token_program))

	tx.update_latest_blockhash("")
	
	tx.sign_and_send()
	
	
	return tx

func get_token_balance(owner_wallet, mint):
	var rpc_result = SolanaClient.get_token_accounts_by_owner(owner_wallet, mint, w3.PID)
	print(rpc_result)
	var token_acc := ""
	if rpc_result.has("result"):
		token_acc = rpc_result["result"]["value"][0]["pubkey"]
		print(token_acc)
	else:
		return 0
		
	rpc_result = SolanaClient.get_token_account_balance(token_acc)
	if rpc_result.has("result"):
		return rpc_result["result"]["value"]["amount"]
	
	return 0


func get_token_balances():
	return [
		get_token_balance(w3.play_keypair.get_public_value(), BOARD_TOKEN),
		get_token_balance(w3.play_keypair.get_public_value(), ENGINE_TOKEN),
		get_token_balance(w3.play_keypair.get_public_value(), GUN_TOKEN)
	]
