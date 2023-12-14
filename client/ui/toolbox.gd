extends Control

signal grab_component(mesh, type)
signal pcb_item_selected
signal edge_item_selected
signal any_item_selected
signal mode_toggled

var actions := []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func toggle():
	for button in $VBoxContainer.get_children():
		button.visible = !button.visible
	emit_signal("mode_toggled")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func store_action(pos: Vector2i, type: int):
	actions.append([pos, type])
	print(actions)
	
func pop_action():
	actions.pop_back()

func tx_error(error):
	print(error)

func commit_changes():
	if actions.size() > 0:
		var tx = w3.send_commit_transaction(actions)
		#print(await tx.transaction_response)
		await get_tree().create_timer(0.2).timeout;
	
	actions.clear()
	toggle()

func _on_button_button_down():
	var obj = preload("res://spacecraft/board.blend").instantiate().get_node("normal").duplicate()
	emit_signal("grab_component", obj, 1)
	emit_signal("pcb_item_selected")
	pass # Replace with function body.


func _on_button_2_button_down():
	var obj = preload("res://components/component.blend").instantiate()
	emit_signal("grab_component", obj, 2)
	emit_signal("any_item_selected")
	pass # Replace with function body.


func _on_button_3_button_down():
	var obj = preload("res://components/engine_1.tscn").instantiate()
	emit_signal("grab_component", obj, 3)
	emit_signal("edge_item_selected")
	pass # Replace with function body.
