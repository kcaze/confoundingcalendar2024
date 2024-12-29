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
	$Sprite.material = $Sprite.material.duplicate()
	$SelectedOutline.material = $SelectedOutline.material.duplicate()

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
	$Sprite.texture = TEX_SALMON if energy > 0 or not energy_depleting else TEX_SALMON_TIRED
	var in_water = grid_pos.y > 17 or grid_pos.y - dir.y > 17
	var rot = int(-$Sprite.rotation_degrees + 360)%360
	($Sprite.material as ShaderMaterial).set_shader_parameter("in_water", in_water)
	($Sprite.material as ShaderMaterial).set_shader_parameter("rotation", rot)
	($Sprite.material as ShaderMaterial).set_shader_parameter("flip_v", dir == DOWN)
	($SelectedOutline.material as ShaderMaterial).set_shader_parameter("in_water", in_water)
	($SelectedOutline.material as ShaderMaterial).set_shader_parameter("rotation", rot)
	($SelectedOutline.material as ShaderMaterial).set_shader_parameter("flip_v", dir == DOWN)
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
	
	if dir.y == 0:
		$Sweat1.position = Vector2(18, -8)
		$Sweat2.position = Vector2(-18, -8)
	if dir.y == -1:
		$Sweat1.position = Vector2(13, -13)
		$Sweat2.position = Vector2(-13, -13)
	if dir.y == 1:
		$Sweat1.position = Vector2(13, 9)
		$Sweat2.position = Vector2(-13, 9)
	$Sweat1.visible = energy_depleting and energy > 0
	$Sweat2.visible = energy_depleting and energy > 0
