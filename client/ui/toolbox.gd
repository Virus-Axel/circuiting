extends Control

signal grab_component(mesh)

var actions := []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func store_action(pos: Vector2i, type: int):
	actions.append([pos, type])
	
func pop_action():
	actions.pop_back()

func commit_changes():
	var tx = Transaction.new()
	w3.send_commit_transaction(actions)

func _on_button_button_down():
	var obj = preload("res://spacecraft/board.blend").instantiate().get_node("normal").duplicate()
	emit_signal("grab_component", obj)
	pass # Replace with function body.
