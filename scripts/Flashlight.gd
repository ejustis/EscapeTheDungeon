extends Spatial
signal light_is_out

var light_source
var energy_current setget energy_current_set, energy_current_get
var energy_max

# Called when the node enters the scene tree for the first time.
func _ready():
	light_source = $Light
	energy_max = 2
	energy_current = energy_max

func energy_current_get():
	return energy_current
	
func energy_current_set(value:float):
	energy_current = clamp(value, 0, energy_max)
	
	light_source.set_param(Light.PARAM_ENERGY, energy_current)
	print("Light energy: ", energy_current)
	
	#Trigger the bad end if light goes out
	if energy_current == 0:
		emit_signal("light_is_out")

func toggle_light():
	light_source.visible = !light_source.visible
