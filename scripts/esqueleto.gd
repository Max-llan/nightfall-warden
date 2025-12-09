extends PathFollow2D
var velocidad = .05
var vida = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	$".".rotation = 0
	$AnimatedSprite2D.play("caminar")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if $AnimatedSprite2D.animation == "caminar":
		progress_ratio += velocidad * _delta
	if vida <= 0:
		$".".queue_free()
	if progress_ratio == 1:
		$".".queue_free()


func _on_area_2d_area_entered(area):
	if area.is_in_group("torreta"):
		$AnimatedSprite2D.play("ataca")
	if area.is_in_group("bala"):
		vida -= 1
		print(vida)
		
func _on_area_2d_area_exited(_area):
	$AnimatedSprite2D.play("caminar")
	
