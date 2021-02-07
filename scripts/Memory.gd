extends MeshInstance
signal activated

var is_active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func disable_and_hide():
	if is_active:
		hide()
		is_active = false
		emit_signal("activated")
