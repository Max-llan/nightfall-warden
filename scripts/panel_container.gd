extends PanelContainer

var torretas = preload("res://scenes/torreta.tscn")
var construccion = false
var conteo = 0

func _ready():
	self_modulate = "ffffff00"
		

func _process(_delta):
	conteo = $Marker2D.get_child_count()
	if conteo == 1:
		construccion = true
	if construccion == true:
		if Global.comprovacion == true:
			if Input.is_action_just_pressed("click"):
				if conteo == 0:
					var player = torretas.instantiate()
					$Marker2D.add_child(player)
					construccion = false
					get_tree().get_nodes_in_group("Main")[0]._reset()
					print(conteo)
		

func _on_mouse_entered():
	if conteo == 0:
		Global.comprovacion = true
		construccion = true
		Global.ubicacion = $Marker2D.global_position
		print(construccion)
	



func _on_mouse_exited() -> void:
	if conteo == 0:
		construccion = false
		Global.comprovacion = false
		Global.ubicacion = get_global_mouse_position()
		print(construccion)
	
