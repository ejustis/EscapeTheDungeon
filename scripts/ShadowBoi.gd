extends KinematicBody

signal touched_player

var path = []
var path_node = 0

var speed = 3
const MAX_SLOPE_ANGLE = 40

onready var nav = get_parent()
onready var player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if path_node < path.size():
		var direction = (path[path_node] - global_transform.origin)
		if direction.length() < 1:
			path_node += 1
		else:
			move_and_slide(direction.normalized() * speed, Vector3.UP, 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
			check_for_player_collision()
	

func check_for_player_collision():
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.get_collider().is_in_group("player"):
			emit_signal("touched_player")
		
	
func move_to(target_pos):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0

func _on_Timer_timeout():
	move_to(player.global_transform.origin)

