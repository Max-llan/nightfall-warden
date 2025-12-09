extends Node2D
var bala = preload("res://scenes/bala.tscn")
var vida = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("idle")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if vida == 0:
		$".".queue_free()
		

	
func _on_area_2d_area_entered(area):
	if area.is_in_group("esqueleto"):
		$Timer.start()
		
func _on_timer_timeout():
	vida -= 1
		
func ataque():
	var ataque = bala.instantiate()
	$Marker2D.add_child(ataque)
	

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "atacar":
		ataque()
		
func det_esqueleto():
	if $RayCast2D.is_colliding():
		$AnimatedSprite2D.play("atacar")
		
	else:
		$AnimatedSprite2D.play("idle")
