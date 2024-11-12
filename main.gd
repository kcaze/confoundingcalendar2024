extends Node2D

const S_SALMON = preload("res://salmon.tscn")
const S_WATERFALL_SPRAY = preload("res://waterfall_spray.tscn")
const WATERFALL_TOP = 2
const WATERFALL_BOTTOM = 17
const WATERFALL_LEFT = 2
const WATERFALL_RIGHT = 8
var ROCKS = {}

var undo_stack = []
var salmons : Array[Salmon] = []
var pools = []
var idx_selected = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize Rocks
	for y in range(2, 18):
		for x in range(0, 2):
			ROCKS[Vector2(x,y)] = true
		for x in range(9, 11):
			ROCKS[Vector2(x,y)] = true
	for x in range(11):
		ROCKS[Vector2(x, 20)] = true
	for y in range(18, 20):
		ROCKS[Vector2(-1, y)] = true
		ROCKS[Vector2(11, y)] = true
	add_salmon(8, 18, Vector2(0,-1),4)
	add_salmon(6, 18, Vector2(0,-1),3)
	add_salmon(4, 18, Vector2(0,-1),2)
	add_salmon(2, 18, Vector2(0,-1),1)
	for pool in get_tree().get_nodes_in_group("2pool"):
		var pos = Vector2(floor((pool.position.x-8)/16), floor(pool.position.y/16))
		pools.append(pos)
		pools.append(pos+Vector2(1,0))

# (x,y) refer to the head position
func add_salmon(x, y, dir, max_energy):
	var salmon = S_SALMON.instantiate()
	salmon.grid_pos = Vector2(x, y)
	salmon.dir = dir
	salmon.max_energy = max_energy
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
	if Input.is_action_just_pressed("UNDO"):
		if len(undo_stack) > 0:
			deserialize(undo_stack.pop_back())

func move_salmon(dir):
	var state = serialize()
	
	var new_pos = salmons[idx_selected].grid_pos + dir
	var in_pool = {}
	
	var to_push = {}
	var pushed_into_rocks = false
	for i in range(len(salmons)):
		if i == idx_selected:
			continue
		var other_pos = salmons[i].grid_pos
		var other_dir = salmons[i].dir
		
		# Calculate to_push list.
		if new_pos == other_pos or new_pos == other_pos - other_dir:
			to_push[i] = true
			var curr = {i: true}
			while len(curr) > 0:
				var new_curr = {}
				for c in curr:
					var curr_pos = [
						salmons[c].grid_pos + dir,
						salmons[c].grid_pos - salmons[c].dir + dir,
					]
					for p in curr_pos:
						for j in range(len(salmons)):
							if j in to_push:
								continue
							if p == salmons[j].grid_pos or p == salmons[j].grid_pos - salmons[j].dir: 
								new_curr[j] = true
						if p in ROCKS:
							pushed_into_rocks = true
						if p in pools and dir == Vector2(0,-1):
							pushed_into_rocks = true
					if salmons[c].dir.y != 0:
						var bottom = Vector2(salmons[c].grid_pos.x, 
							salmons[c].grid_pos.y + (1 if salmons[c].dir.y < 0 else 0)) + dir
						var top = Vector2(salmons[c].grid_pos.x,
							salmons[c].grid_pos.y + (-1 if salmons[c].dir.y > 0 else 0)) + dir
						if top in pools and bottom not in pools:
							pushed_into_rocks = true
				for c in new_curr:
					to_push[c] = true
				curr = new_curr
		
	if not new_pos in ROCKS and not pushed_into_rocks and salmons[idx_selected].energy > 0 and not (new_pos-Vector2(0,1) in pools and dir == Vector2(0,1)) and not (new_pos in pools and dir == Vector2(0, -1)):
		for i in to_push:
			salmons[i].grid_pos += dir
		salmons[idx_selected].grid_pos += dir
		salmons[idx_selected].dir = dir
	
	for i in range(len(salmons)):
		in_pool[i] = false
		for p in pools:
			if salmons[i].grid_pos == p or salmons[i].grid_pos - salmons[i].dir == p:
				in_pool[i] = true
			
	# Restore energy for any salmon that are now below the waterfall
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y >= 18 or in_pool[i]:
			salmons[i].energy = salmons[i].max_energy


	# Drop salmon that are out of energy, letting them rest on another salmon if possible.
	var tired_salmon = {}
	for i in range(len(salmons)):
		if salmons[i].energy == 0:
			tired_salmon[i] = true
	while len(tired_salmon) > 0:
		var i = tired_salmon.keys()[0]
		var to_drop = {i: true}
		var curr = {i: true}
		var can_push = true
		while len(curr) > 0:
			var new_curr = {}
			for c in curr:
				var curr_pos = [
					salmons[c].grid_pos + Vector2(0, 1),
					salmons[c].grid_pos - salmons[c].dir + Vector2(0, 1),
				]
				for p in curr_pos:
					for j in range(len(salmons)):
						if j in to_drop:
							continue
						if p == salmons[j].grid_pos or p == salmons[j].grid_pos - salmons[j].dir:
							if j in tired_salmon:
								new_curr[j] = true
							else:
								can_push = false
						if p in ROCKS:
							can_push = false
						if p+Vector2(0,-1) in pools:
							can_push = false
			for c in new_curr:
				to_drop[c] = true
			curr = new_curr
		if can_push:
			for c in to_drop:
				tired_salmon.erase(c)
				salmons[c].grid_pos += Vector2(0,1)
		else:
			tired_salmon.erase(i)
	
	for i in range(len(salmons)):
		for p in pools:
			if salmons[i].grid_pos == p or salmons[i].grid_pos - salmons[i].dir == p:
				in_pool[i] = true
	
	# Lower energy for all salmon in waterfall
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y < 18 and (salmons[i].grid_pos - salmons[i].dir).y < 18 and not in_pool[i]:
			var is_covered = [salmons[i].grid_pos, salmons[i].grid_pos - salmons[i].dir]
			# Don't lower energy if there is a salmon above.
			#for j in range(len(salmons)):
				#if j == i:
					#continue
				#for c in range(2):
					#if typeof(is_covered[c]) == TYPE_BOOL:
						#continue
					#for p in [salmons[j].grid_pos, salmons[j].grid_pos - salmons[j].dir]:
						#if p.x == is_covered[c].x and p.y < is_covered[c].y:
							#is_covered[c] = true
							#break
			if typeof(is_covered[0]) != TYPE_BOOL or typeof(is_covered[1]) != TYPE_BOOL:
				salmons[i].energy = max(0, salmons[i].energy-1)
	
	# Restore energy for any salmon that are now below the waterfall
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y >= 18 or in_pool[i]:
			salmons[i].energy = salmons[i].max_energy
	
	if len(undo_stack) == 0 or not deep_equals(state, undo_stack[-1]):
		undo_stack.push_back(state)

func serialize():
	var state = []
	for s in salmons:
		state.append({"grid_pos": s.grid_pos, "dir": s.dir, "energy": s.energy})
	return state

func deserialize(state):
	for i in range(len(salmons)):
		salmons[i].grid_pos = state[i]["grid_pos"]
		salmons[i].dir = state[i]["dir"]
		salmons[i].energy = state[i]["energy"]

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
