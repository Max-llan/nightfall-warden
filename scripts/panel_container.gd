extends PanelContainer

var torretas = preload("res://scenes/torreta.tscn")
var tiene_torreta = false

func _ready():
	self_modulate = Color(1, 1, 1, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(_delta):
	tiene_torreta = $Marker2D.get_child_count() > 0
	
	# Colocar torreta cuando hace click en modo compra
	if Global.modo_compra and not tiene_torreta:
		if Input.is_action_just_pressed("click"):
			var mouse_pos = get_global_mouse_position()
			var rect = get_global_rect()
			if rect.has_point(mouse_pos):
				if Global.gastar_monedas(Global.costo_torreta):
					# Crear torreta permanente
					var torreta_permanente = torretas.instantiate()
					$Marker2D.add_child(torreta_permanente)
					torreta_permanente.global_position = $Marker2D.global_position
					
					if torreta_permanente.has_method("set_carril"):
						torreta_permanente.set_carril(get_carril_actual())
					
					# Limpiar torreta temporal
					get_tree().get_nodes_in_group("Main")[0]._reset()
					
					# Resetear modo compra
					Global.modo_compra = false
					Global.comprovacion = false

func get_carril_actual() -> float:
	return $Marker2D.global_position.y

func _on_mouse_entered():
	if not tiene_torreta and Global.modo_compra:
		Global.comprovacion = true
		Global.ubicacion = $Marker2D.global_position
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited() -> void:
	Global.comprovacion = false
	modulate = Color(1, 1, 1)

