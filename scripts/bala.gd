extends Node2D

var velocidad = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position.x += velocidad * _delta
	

func _on_area_2d_area_entered(area):
	if area.is_in_group("esqueleto"):
		$".".queue_free()
