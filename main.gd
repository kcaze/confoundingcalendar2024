extends Node2D

const S_SALMON = preload("res://salmon.tscn")

var salmons = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_salmon(0, 18, Vector2(-1,0))
	add_salmon(3, 18, Vector2(1,0))
	add_salmon(0, 16, Vector2(0,-1))
	add_salmon(3, 17, Vector2(0, 1))
	pass # Replace with function body.

# (x,y) refer to the head position
func add_salmon(x, y, dir):
	var salmon = S_SALMON.instantiate()
	salmon.grid_pos = Vector2(x, y)
	salmon.dir = dir
	salmons.append(salmon)
	$Salmons.add_child(salmon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
