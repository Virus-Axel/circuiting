extends VBoxContainer



func _on_balance_update_timer_timeout():
	var balances = w3.get_node("tokens").get_token_balances()
	print(balances)
	$Button/Label.text = str(balances[0])
	$Button3/Label.text = str(balances[1])
	$Button2/Label.text = str(balances[2])
