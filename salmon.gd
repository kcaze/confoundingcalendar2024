extends Node2D
class_name Salmon

const TEX_ENERGY = preload("res://assets/sprites/energy.png")
const TEX_ENERGY_EMPTY = preload("res://assets/sprites/energy_empty.png")

const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)

var grid_pos = Vector2(0,0)
var dir = Vector2(1,0)
var selected = false
var max_energy = 4
var energy = max_energy
var energy_sprites = []
var in_waterfall = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(max_energy):
		var sprite = Sprite2D.new()
		sprite.texture = TEX_ENERGY
		sprite.z_index = 30
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
		$Sprite.flip_h = true
	if dir == UP:
		$Sprite.rotation_degrees = -90
		$Sprite.flip_h = false
	if dir == RIGHT:
		$Sprite.rotation_degrees = 0
		$Sprite.flip_h = false
	if dir == DOWN:
		$Sprite.rotation_degrees = -90
		$Sprite.flip_h = true
	
	# Selected outline
	if selected and $Sprite.animation != "selected":
		$Sprite.play("selected")
	if not selected and $Sprite.animation != "default":
		$Sprite.play("default")
	
	# Selected z-index
	if selected:
		z_index = 30
	else:
		z_index = 0
	
	# Energy icons
	var center = Vector2(0, -13) if dir.y == 0 else Vector2(0,-22)
	for i in range(max_energy):
		energy_sprites[i].position = center + Vector2(6 * (i - (max_energy-1)/2.0),0)
