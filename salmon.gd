extends Sprite2D

const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)

var grid_pos = Vector2(0,0)
var dir = Vector2(1,0)
var selected = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func serialize():
	return {
		"grid_pos": grid_pos,
		"dir": dir
	}
	
func deserialize(obj):
	grid_pos = obj["grid_pos"]
	dir = obj["dir"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = (grid_pos - dir*0.5 + Vector2(0.5,0.5)) * 16
	if dir == LEFT:
		rotation_degrees = 0
		flip_h = true
	if dir == UP:
		rotation_degrees = -90
		flip_h = false
	if dir == RIGHT:
		rotation_degrees = 0
		flip_h = false
	if dir == DOWN:
		rotation_degrees = -90
		flip_h = true
