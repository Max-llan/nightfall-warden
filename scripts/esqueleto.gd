extends PathFollow2D
var velocidad = .055  # Aumentada de .045 a .055 (más rápido y desafiante)
var vida = 100  # Vida base inicial más baja
var esta_atacando_torreta = false
var torreta_objetivo = null
var danio_ataque = 100
var timer_ataque: Timer
var distancia_deteccion = 60.0  # Distancia para detectar torretas delante
var torretas_en_rango = []  # Lista de torretas detectadas
var ya_murio = false

# Variables base para aplicar dificultad
var velocidad_base = .055
var vida_base = 100  # Vida base inicial
var vida_maxima = 100

# Variables para esqueletos grandes
var es_esqueleto_grande = false
var escala_original = Vector2(1.0, 1.0)

func _ready():
	# Desactivar la rotación automática del PathFollow2D
	rotates = false
	$".".rotation = 0
	$AnimatedSprite2D.play("caminar")
	
	# Guardar escala original
	escala_original = scale
	
	# Crear timer para atacar a la torreta
	timer_ataque = Timer.new()
	timer_ataque.wait_time = 0.4
	timer_ataque.one_shot = false
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	add_child(timer_ataque)
	
	# Configurar el Area2D del esqueleto para detectar el área de perder
	if has_node("Area2D"):
		var area = get_node("Area2D")
		# Layer 2 para el esqueleto, Mask 1 para detectar el área de perder
		area.collision_layer = 2
		area.collision_mask = 1
		area.add_to_group("esqueleto")

func aplicar_dificultad(mult_velocidad: float, mult_vida: float, es_grande: bool = false):
	es_esqueleto_grande = es_grande
	
	# Calcular oleada actual desde main
	var main = get_tree().current_scene
	var oleada = 1
	if main and main.has_method("get"):
		oleada = main.get("oleada_actual") if main.get("oleada_actual") != null else 1
	
	# Aumentar vida base progresivamente desde oleada 3
	var vida_escalada = vida_base
	if oleada >= 3:
		# +20 HP por oleada a partir de la oleada 3
		vida_escalada = vida_base + ((oleada - 2) * 20)
	
	if es_grande:
		# Esqueleto GRANDE: Más lento pero MUCHO más resistente
		velocidad = velocidad_base * mult_velocidad * 0.6  # 40% más lento
		vida = int(vida_escalada * mult_vida * 3.0)  # Aumentado de 2.5 a 3.0 para más resistencia
		vida_maxima = vida
		danio_ataque = 150  # Hace más daño también
		
		# Aumentar tamaño visual (30% más grande)
		scale = escala_original * 1.3
		
		# Darle un tinte rojo para diferenciarlo
		modulate = Color(1.2, 0.8, 0.8)
	else:
		# Esqueleto normal
		velocidad = velocidad_base * mult_velocidad
		vida = int(vida_escalada * mult_vida)
		vida_maxima = vida

func _process(_delta):
	if vida <= 0:
		morir()
		return
	
	# Limpiar lista de torretas que ya no existen
	torretas_en_rango = torretas_en_rango.filter(func(t): return is_instance_valid(t))
	
	# Si no está atacando, buscar torretas delante
	if not esta_atacando_torreta:
		buscar_y_atacar_torreta()
	
	# Si está atacando, verificar que la torreta siga existiendo
	if esta_atacando_torreta:
		if not is_instance_valid(torreta_objetivo):
			# La torreta fue destruida, dejar de atacar y buscar la siguiente
			dejar_de_atacar()
			buscar_y_atacar_torreta()
		else:
			# Verificar distancia a la torreta
			var distancia = global_position.distance_to(torreta_objetivo.global_position)
			if distancia <= distancia_deteccion:
				# Atacar
				if $AnimatedSprite2D.animation != "ataca":
					$AnimatedSprite2D.play("ataca")
			else:
				# Seguir caminando hacia la torreta
				if $AnimatedSprite2D.animation != "caminar":
					$AnimatedSprite2D.play("caminar")
				progress_ratio += velocidad * _delta
	else:
		# Moverse normalmente
		if $AnimatedSprite2D.animation != "caminar":
			$AnimatedSprite2D.play("caminar")
		progress_ratio += velocidad * _delta
	
	# Si llegó al final del camino (cerca del área de perder)
	if progress_ratio >= 0.98:  # Detectar antes de llegar al final exacto
		# El área de perder lo detectará automáticamente
		pass
	
	# Si llegó al final, destruir
	if progress_ratio >= 1:
		queue_free()

func buscar_y_atacar_torreta():
	# Buscar la torreta más cercana que esté DELANTE del esqueleto
	var torreta_mas_cercana = null
	var distancia_minima = 99999.0
	
	for torreta in torretas_en_rango:
		if is_instance_valid(torreta):
			# Verificar que la torreta esté DELANTE (menor X en este caso)
			if torreta.global_position.x < global_position.x:
				var distancia = global_position.distance_to(torreta.global_position)
				if distancia < distancia_minima and distancia <= distancia_deteccion:
					distancia_minima = distancia
					torreta_mas_cercana = torreta
	
	# Si encontró una torreta, comenzar a atacarla
	if torreta_mas_cercana != null:
		esta_atacando_torreta = true
		torreta_objetivo = torreta_mas_cercana
		timer_ataque.start()
		$AnimatedSprite2D.play("ataca")

func dejar_de_atacar():
	esta_atacando_torreta = false
	torreta_objetivo = null
	timer_ataque.stop()
	if vida > 0:
		$AnimatedSprite2D.play("caminar")

func recibir_danio(cantidad):
	if ya_murio:
		return
		
	vida -= cantidad
	# Efecto visual de daño
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if vida > 0:
		modulate = Color(1, 1, 1)
	else:
		morir()

func morir():
	# Verificar que no se haya ejecutado ya
	if ya_murio:
		return
	
	ya_murio = true
	
	# Detener timer de ataque
	if timer_ataque:
		timer_ataque.stop()
	
	# Crear moneda(s) en la posición del esqueleto
	var moneda_scene = preload("res://scenes/moneda.tscn")
	
	# Los esqueletos grandes dan 2 monedas (100 pesos total)
	var cantidad_monedas = 2 if es_esqueleto_grande else 1
	
	for i in range(cantidad_monedas):
		var moneda = moneda_scene.instantiate()
		# Distribuir las monedas un poco para que no estén una encima de la otra
		var offset = Vector2(i * 20 - 10, randf_range(-10, 10))
		moneda.global_position = global_position + offset
		get_tree().root.get_node("main").add_child(moneda)
	
	# Animación de muerte
	$AnimatedSprite2D.stop()
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _on_area_2d_area_entered(area):
	if area.is_in_group("torreta"):
		# Encontrar la torreta (el padre del Area2D)
		var torreta = area.get_parent()
		
		if torreta and torreta.has_method("recibir_danio"):
				# Verificar que sea una torreta colocada (no temporal)
			if torreta.get("es_torreta_colocada") == true:
				# Agregar a la lista de torretas en rango si no está ya
				if not torreta in torretas_en_rango:
					torretas_en_rango.append(torreta)

func _on_area_2d_area_exited(area):
	if area.is_in_group("torreta"):
		var torreta = area.get_parent()
		if torreta and torreta in torretas_en_rango:
			torretas_en_rango.erase(torreta)
			
			# Si era la torreta que estaba atacando, dejar de atacar
			if torreta == torreta_objetivo:
				dejar_de_atacar()

func _on_timer_ataque_timeout():
	# Atacar a la torreta
	if esta_atacando_torreta and is_instance_valid(torreta_objetivo):
		var distancia = global_position.distance_to(torreta_objetivo.global_position)
		if distancia <= distancia_deteccion:
			if torreta_objetivo.has_method("recibir_danio"):
				torreta_objetivo.recibir_danio(danio_ataque)

