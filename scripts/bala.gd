extends Node2D

var velocidad = 300
var objetivo = null
var danio = 20  # Daño reducido a 20 HP por bala

func _ready():
	pass

func set_objetivo(nuevo_objetivo):
	objetivo = nuevo_objetivo

func _process(delta):
	# Si hay objetivo válido, perseguirlo
	if objetivo != null and is_instance_valid(objetivo):
		var direccion = (objetivo.global_position - global_position).normalized()
		global_position += direccion * velocidad * delta
		
		# Rotar la bala hacia el objetivo
		rotation = direccion.angle()
		
		# Verificar si llegó al objetivo
		if global_position.distance_to(objetivo.global_position) < 10:
			if objetivo.has_method("recibir_danio"):
				objetivo.recibir_danio(danio)
			queue_free()
	else:
		# Si no hay objetivo, moverse horizontalmente
		position.x += velocidad * delta
	
	# Destruir bala si sale de la pantalla
	if global_position.x > 1200 or global_position.x < -100:
		queue_free()

func _on_area_2d_area_entered(area):
	if area.is_in_group("esqueleto"):
		var enemigo = area.get_parent()
		if enemigo and enemigo.has_method("recibir_danio"):
			enemigo.recibir_danio(danio)
		queue_free()
