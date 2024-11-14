extends Node2D
class_name Salmon

const TEX_SALMON_TIRED = preload("res://assets/sprites/salmon_tired.png")
const TEX_SALMON = preload("res://assets/sprites/salmon.png")
const S_ENERGY = preload("res://energy.tscn")

const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)

var grid_pos = Vector2(0,0)
var dir = Vector2(1,0)
var selected = false
var max_energy = 5
var energy = max_energy
var energy_sprites = []
var energy_depleting = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	energy = max_energy
	for i in range(max_energy):
		var sprite = S_ENERGY.instantiate()
		energy_sprites.append(sprite)
		add_child(sprite)

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
		$Sprite.rotation_degrees = 0
		$SelectedOutline.rotation_degrees = 0
		$Sprite.flip_h = true
		$SelectedOutline.flip_h = true
	if dir == UP:
		$Sprite.rotation_degrees = -90
		$SelectedOutline.rotation_degrees = -90
		$Sprite.flip_h = false
		$SelectedOutline.flip_h = false
	if dir == RIGHT:
		$Sprite.rotation_degrees = 0
		$SelectedOutline.rotation_degrees = 0
		$Sprite.flip_h = false
		$SelectedOutline.flip_h = false
	if dir == DOWN:
		$Sprite.rotation_degrees = -90
		$SelectedOutline.rotation_degrees = -90
		$Sprite.flip_h = true
		$SelectedOutline.flip_h = true
	
	# Selected outline
	$SelectedOutline.visible = selected
	$Sprite.texture = TEX_SALMON if energy > 0 else TEX_SALMON_TIRED
	
	# Selected z-index
	z_index = 15 if selected else 5
	
	# Energy icons
	var center = Vector2(0, -13) if dir.y == 0 else Vector2(0,-22)
	for i in range(max_energy):
		energy_sprites[i].position = center + Vector2(6 * (i - (max_energy-1)/2.0),0)
		if i < energy-1:
			energy_sprites[i].play("default")
		elif i == energy-1:
			energy_sprites[i].play("depleting" if energy_depleting else "default")
		else:
			energy_sprites[i].play("empty")
