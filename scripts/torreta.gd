extends Node2D
var bala = preload("res://scenes/bala.tscn")
var vida = 300  # Vida aumentada a 300 HP
var vida_maxima = 300
var enemigos_en_rango = []
var puede_disparar = true
var intervalo_disparo = 1.5  # Cambiado a 1.5 segundos
var timer_disparo: Timer
var rango_deteccion = 750  # Aumentado de 500 a 750 para detectar casi al aparecer
var carril_y = 0.0
var tolerancia_carril = 80.0  # Aumentado para mejor detección de carriles
var es_torreta_colocada = false  # Nueva variable para identificar torretas colocadas

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("idle")
	
	# Guardar la posición Y del carril
	carril_y = global_position.y
	
	# Crear el timer de disparo programáticamente
	timer_disparo = Timer.new()
	timer_disparo.wait_time = intervalo_disparo
	timer_disparo.one_shot = false
	timer_disparo.timeout.connect(_on_timer_disparo_timeout)
	add_child(timer_disparo)
	
	# Configurar el área de detección más amplia
	if has_node("Area2D"):
		var collision = $Area2D/CollisionShape2D
		if collision.shape is RectangleShape2D:
			collision.shape.size.x = rango_deteccion
			# Centrar el área de detección hacia adelante
			collision.position.x = rango_deteccion / 2.0
	
	# Configurar audio con volumen reducido para evitar saturación
	if has_node("AudioStreamPlayer"):
		var audio = $AudioStreamPlayer
		audio.volume_db = -18.0
		audio.max_polyphony = 3

func set_carril(y_position: float):
	carril_y = y_position
	es_torreta_colocada = true  # Marcar como torreta colocada

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if vida <= 0:
		morir()
		return
	
	# Detectar y atacar enemigos continuamente
	detectar_y_atacar()

func recibir_danio(cantidad):
	vida -= cantidad
	print("Torreta recibe daño. Vida actual: ", vida)  # Debug
	# Efecto visual de daño
	modulate = Color(1, 0.3, 0.3)  # Flash rojo
	await get_tree().create_timer(0.1).timeout
	if vida > 0:
		modulate = Color(1, 1, 1)
	else:
		morir()

func morir():
	print("Torreta muriendo...")  # Debug
	# Detener todos los timers
	if timer_disparo:
		timer_disparo.stop()
	
	# Remover del grupo torreta para que los esqueletos no la detecten
	if is_in_group("torreta"):
		remove_from_group("torreta")
	
	# Desactivar colisiones
	if has_node("Area2D"):
		$Area2D.set_deferred("monitoring", false)
		$Area2D.set_deferred("monitorable", false)
	
	# Animación de destrucción de torreta
	$AnimatedSprite2D.stop()
	modulate = Color(1, 0, 0, 0.5)  # Rojo transparente
	await get_tree().create_timer(0.3).timeout
	queue_free()

func detectar_y_atacar():
	# Limpiar enemigos que ya no existen o no están en el carril
	enemigos_en_rango = enemigos_en_rango.filter(func(e): 
		return is_instance_valid(e) and esta_en_mismo_carril(e)
	)
	
	# Verificar si hay enemigos en rango
	if enemigos_en_rango.size() > 0:
		# Buscar el enemigo más cercano en el mismo carril
		var enemigo_objetivo = encontrar_enemigo_mas_cercano()
		
		if enemigo_objetivo != null and puede_disparar:
			# Disparar al enemigo
			$AnimatedSprite2D.play("atacar")
			disparar(enemigo_objetivo)
			puede_disparar = false
			timer_disparo.start()
	else:
		# Volver a idle si no hay enemigos
		if $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

func esta_en_mismo_carril(enemigo) -> bool:
	# Verificar si el enemigo está en el mismo carril (misma línea horizontal)
	if not is_instance_valid(enemigo):
		return false
	var diferencia_y = abs(enemigo.global_position.y - carril_y)
	return diferencia_y <= tolerancia_carril

func encontrar_enemigo_mas_cercano():
	if enemigos_en_rango.size() == 0:
		return null
	
	var enemigo_cercano = null
	var distancia_minima = 99999.0
	
	for enemigo in enemigos_en_rango:
		if is_instance_valid(enemigo) and esta_en_mismo_carril(enemigo):
			# Calcular distancia horizontal (solo en X)
			var distancia = abs(enemigo.global_position.x - global_position.x)
			if distancia < distancia_minima:
				distancia_minima = distancia
				enemigo_cercano = enemigo
	
	return enemigo_cercano

func disparar(objetivo):
	var nueva_bala = bala.instantiate()
	get_parent().add_child(nueva_bala)
	nueva_bala.global_position = $Marker2D.global_position
	
	# Pasar el objetivo a la bala
	if nueva_bala.has_method("set_objetivo"):
		nueva_bala.set_objetivo(objetivo)
	
	# Reproducir sonido de disparo con volumen controlado
	if has_node("AudioStreamPlayer"):
		var audio = $AudioStreamPlayer
		# Variar ligeramente el pitch para que no suene repetitivo
		audio.pitch_scale = randf_range(0.9, 1.1)
		audio.play()

func _on_area_2d_area_entered(area):
	if area.is_in_group("esqueleto"):
		var enemigo = area.get_parent()
		if enemigo and not enemigos_en_rango.has(enemigo) and esta_en_mismo_carril(enemigo):
			enemigos_en_rango.append(enemigo)

func _on_area_2d_area_exited(area):
	if area.is_in_group("esqueleto"):
		var enemigo = area.get_parent()
		if enemigo and enemigos_en_rango.has(enemigo):
			enemigos_en_rango.erase(enemigo)

func _on_timer_timeout():
	# Este timer ya no se usa para reducir vida automáticamente
	pass

func _on_timer_disparo_timeout():
	puede_disparar = true

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "atacar" and enemigos_en_rango.size() == 0:
		$AnimatedSprite2D.play("idle")
