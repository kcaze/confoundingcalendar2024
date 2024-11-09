extends Sprite2D

const MAX_SPEED = 60

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var speed = min(0.5*(position.y - (-64) + randi_range(0, 30)), MAX_SPEED)
	position.y += speed*delta
	if position.y > 350:
		position.y = -32
