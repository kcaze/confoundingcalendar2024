extends Node2D

const S_SALMON = preload("res://salmon.tscn")
const WATERFALL_TOP = 2
const WATERFALL_BOTTOM = 17
const WATERFALL_LEFT = 2
const WATERFALL_RIGHT = 8
var ROCKS = {}

var undo_stack = []
var salmons : Array[Salmon] = []
var idx_selected = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_salmon(0, 18, Vector2(-1,0))
	add_salmon(3, 18, Vector2(-1,0))
	for y in range(2, 18):
		for x in range(0, 2):
			ROCKS[Vector2(x,y)] = true
		for x in range(9, 11):
			ROCKS[Vector2(x,y)] = true

# (x,y) refer to the head position
func add_salmon(x, y, dir):
	var salmon = S_SALMON.instantiate()
	salmon.grid_pos = Vector2(x, y)
	salmon.dir = dir
	salmons.append(salmon)
	$Salmons.add_child(salmon)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ACTION"):
		idx_selected = (idx_selected + 1) % len(salmons)
	if Input.is_action_just_pressed("UP"):
		move_salmon(Vector2(0,-1))
	if Input.is_action_just_pressed("DOWN"):
		move_salmon(Vector2(0,1))
	if Input.is_action_just_pressed("RIGHT"):
		move_salmon(Vector2(1,0))
	if Input.is_action_just_pressed("LEFT"):
		move_salmon(Vector2(-1,0))

func move_salmon(dir):
	var state = serialize()
	
	var new_pos = salmons[idx_selected].grid_pos + dir
	# Cannot move into rocks
	if new_pos in ROCKS:
		return
	# Cannot move into other salmon
	# TODO: Maybe allow pushing other salmon.
	for i in range(len(salmons)):
		if i == idx_selected:
			continue
		var other_pos = salmons[i].grid_pos
		var other_dir = salmons[i].dir
		if new_pos == other_pos or new_pos == other_pos - other_dir:
			return
	
	
	salmons[idx_selected].grid_pos += dir
	salmons[idx_selected].dir = dir
	if len(undo_stack) == 0 or not deep_equals(state, undo_stack[-1]):
		undo_stack.push_back(state)

func serialize():
	return []

func deep_equals(t, s):
	if typeof(t) != typeof(s):
		return false
	
	if t is Dictionary:
		if not deep_equals(t.keys(), s.keys()):
			return false
		for k in t.keys():
			if not deep_equals(t[k], s[k]):
				return false
		return true
	elif t is Array:
		if len(t) != len(s):
			return false
		for i in range(len(t)):
			if not deep_equals(t[i], s[i]):
				return false
		return true
	else:
		return t == s

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(len(salmons)):
		salmons[i].selected = idx_selected == i
	pass
