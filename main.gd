extends Node2D

const S_SALMON = preload("res://salmon.tscn")
const S_WATERFALL_SPRAY = preload("res://waterfall_spray.tscn")
const TEX_SOUND_ON = preload("res://assets/sprites/sound_on_icon.png")
const TEX_SOUND_OFF = preload("res://assets/sprites/sound_off_icon.png")
const WATERFALL_TOP = 2
const WATERFALL_BOTTOM = 17
const WATERFALL_LEFT = 2
const WATERFALL_RIGHT = 8
var ROCKS = {}

var undo_stack = []
var current_state = null
var save_state = null
var salmons : Array[Salmon] = []
var pools = []
var idx_selected = 0
var win = false
var initial_state = null
var sound_on = true

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
	add_salmon(2, 18, Vector2(0,-1),1)
	add_salmon(4, 18, Vector2(0,-1),2)
	add_salmon(6, 18, Vector2(0,-1),3)
	add_salmon(8, 18, Vector2(0,-1),4)
	#add_salmon(8, 7, Vector2(0,-1),3)
	#add_salmon(8, 9, Vector2(0,-1),2)
	#add_salmon(8, 11, Vector2(0,-1),1)
	for pool in get_tree().get_nodes_in_group("2pool"):
		var pos = Vector2(floor((pool.position.x-8)/16), floor(pool.position.y/16))
		pools.append(pos)
		pools.append(pos+Vector2(1,0))
	
	initial_state = serialize()
	#load_game()
	#salmons[3].grid_pos = Vector2(4, 3)
	#salmons[3].energy = 4
	#salmons[0].grid_pos = Vector2(5, 13)
	#salmons[0].dir = Vector2(1, 0)
	#salmons[1].grid_pos = Vector2(5, 12)
	#salmons[1].dir = Vector2(-1,0)
	#salmons[2].grid_pos = Vector2(4, 14)
	#salmons[2].dir = Vector2(1,0)
	#salmons[3].grid_pos = Vector2(4, 12)
	#salmons[3].dir = Vector2(1,0)
	#for i in range(len(salmons)):
		#salmons[i].energy = salmons[i].max_energy

# (x,y) refer to the head position
func add_salmon(x, y, dir, max_energy):
	var salmon = S_SALMON.instantiate()
	salmon.grid_pos = Vector2(x, y)
	salmon.dir = dir
	salmon.max_energy = max_energy
	salmons.append(salmon)
	$Salmons.add_child(salmon)

func _input(event: InputEvent) -> void:
	if win:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			if $SoundIcon.get_rect().has_point($SoundIcon.to_local(mouse_pos)):
				sound_on = not sound_on
				save_game()
			if $Controls/Close.get_rect().has_point($Controls/Close.to_local(mouse_pos)):
				$Controls.visible = false
			if $InfoIcon.get_rect().has_point($InfoIcon.to_local(mouse_pos)):
				$Controls.visible = true

	if $Controls.visible:
		return
	
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
	for i in range(1, 5):
		if Input.is_action_just_pressed("SELECT"+str(i)):
			for j in range(len(salmons)):
				if salmons[j].max_energy == i:
					idx_selected = j
					break
	if Input.is_action_pressed("UNDO"):
		if len(undo_stack) > 0:
			deserialize(undo_stack.pop_back())
			win = false
	if Input.is_action_just_pressed("SAVE"):
		if not win:
			save_state = serialize()
			$SaveIcon.stop()
			$SaveIcon.play("default")
	if Input.is_action_just_pressed("LOAD"):
		win = false
		if save_state != null:
			deserialize(save_state)
		else:
			deserialize(initial_state)
	
	
func move_salmon(dir):
	if win:
		return
	
	var prev_state = serialize()
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
					if dir == Vector2(0, 1) and (salmons[c].grid_pos in pools or salmons[c].grid_pos - salmons[c].dir in pools):
						pushed_into_rocks = true
				for c in new_curr:
					to_push[c] = true
				curr = new_curr
		
	if not new_pos in ROCKS and not pushed_into_rocks and salmons[idx_selected].energy > 0 and not (new_pos-Vector2(0,1) in pools and dir == Vector2(0,1)) and not (new_pos in pools and dir == Vector2(0, -1)):
		#$SplashAudio.play()
		for i in to_push:
			salmons[i].grid_pos += dir
		salmons[idx_selected].grid_pos += dir
		salmons[idx_selected].dir = dir
	else:
		pass
		#$InvalidAudio.play()
	
	for i in range(len(salmons)):
		in_pool[i] = false
		for p in pools:
			if salmons[i].grid_pos == p or salmons[i].grid_pos - salmons[i].dir == p:
				in_pool[i] = true
			
	# Restore energy for any salmon that are now below the waterfall
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y >= 18 or (salmons[i].grid_pos - salmons[i].dir).y >= 18 or in_pool[i]:
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
				if salmons[i].energy_depleting:
					salmons[i].energy = max(0, salmons[i].energy-1)
	
	# Restore energy for any salmon that are now below the waterfall
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y >= 18 or (salmons[i].grid_pos - salmons[i].dir).y >= 18 or in_pool[i]:
			salmons[i].energy = salmons[i].max_energy
			salmons[i].energy_depleting = false
		else:
			salmons[i].energy_depleting = true
	
	current_state = serialize()
	
	# Check win condition
	for i in range(len(salmons)):
		if salmons[i].grid_pos.y <= 1 or (salmons[i].grid_pos - salmons[i].dir).y <= 1:
			win = true
	
	if not win:
		if len(undo_stack) == 0 or not deep_equals(current_state, prev_state):
			undo_stack.push_back(prev_state)
			save_game()

func serialize():
	var state = []
	for s in salmons:
		state.append({"grid_pos": s.grid_pos, "dir": s.dir, "energy": s.energy, "energy_depleting": s.energy_depleting})
	return state

func deserialize(state):
	for i in range(len(salmons)):
		salmons[i].grid_pos = state[i]["grid_pos"]
		salmons[i].dir = state[i]["dir"]
		salmons[i].energy = state[i]["energy"]
		salmons[i].energy_depleting = state[i]["energy_depleting"]

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
	$WinScreen.visible = win
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_idx, not sound_on)
	$SoundIcon.texture = TEX_SOUND_ON if sound_on else TEX_SOUND_OFF
	if win:
		var mat = ($WinScreen.material as ShaderMaterial)
		mat.set_shader_parameter("t", mat.get_shader_parameter("t")+0.75*delta)
	$InfoIcon.visible = not $Controls.visible
	
func load_game():
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var json_string = save_file.get_as_text()
		var data = str_to_var(json_string)
		current_state = data["current_state"]
		save_state = data["save_state"]
		undo_stack = data["undo_stack"]
		sound_on = data["sound_on"]
		deserialize(current_state)
		
func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(var_to_str({
		"current_state": serialize(),
		"save_state": save_state,
		"undo_stack": undo_stack,
		"sound_on": sound_on
	}))
