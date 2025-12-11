extends Node2D
var torretas = preload("res://scenes/torreta.tscn")
var esqueleto = preload("res://scenes/esqueleto.tscn")

# Sistema de oleadas
var oleada_actual = 0
var esqueletos_por_oleada = 2
var tiempo_entre_spawns = 2.0
var tiempo_entre_oleadas = 10.0
var esqueletos_spawneados = 0
var oleada_en_progreso = false
var juego_terminado = false

# Sistema de dificultad progresiva
var nivel_dificultad = 0  # Aumenta cada 5 oleadas
var multiplicador_velocidad = 1.0
var multiplicador_vida = 1.0

# Sistema de spawns simultáneos
var max_spawns_simultaneos = 1  # Empieza en 1
var carriles_usados_este_frame = []

var timer_spawn: Timer
var timer_oleada: Timer

# Sistema de score (tiempo transcurrido)
var tiempo_transcurrido = 0

# Referencias a los Path2D (carriles)
var carriles = []

func _ready() -> void:
	# Ocultar el game over al inicio
	$gameover.visible = false
	
	# IMPORTANTE: Configurar gameover para que funcione cuando el juego está pausado
	$gameover.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Configurar y iniciar el timer de score
	$HUD/ScreenTime.wait_time = 1.0  # 1 segundo
	$HUD/ScreenTime.timeout.connect(_on_screen_time_timeout)
	$HUD/ScreenTime.start()
	
	# Inicializar el score en 0
	$HUD/Score.text = "0"
	
	# Ocultar el label de oleada inicialmente
	if has_node("HUD/oleadas"):
		$HUD/oleadas.visible = false
	
	# Mostrar la nota por 2 segundos y luego ocultarla
	$HUD/nota.visible = true
	await get_tree().create_timer(2.0).timeout
	$HUD/nota.visible = false
	
	# Configurar el área de perder con las capas correctas
	if has_node("elementos/perder"):
		var area_perder = $elementos/perder
		area_perder.collision_layer = 1  # Layer 1 para el área de perder
		area_perder.collision_mask = 2   # Mask 2 para detectar esqueletos
	
	# Configurar el Control para que NO bloquee los clicks a las monedas
	var control = $Control
	if control:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Configurar HBoxContainer para que tampoco bloquee
	var hbox = $Control/HBoxContainer
	if hbox:
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Obtener todos los carriles (Path2D)
	carriles = [
		$Path2D,
		$Path2D2,
		$Path2D3,
		$Path2D4,
		$Path2D5
	]
	
	# Crear timer para spawn de esqueletos
	timer_spawn = Timer.new()
	timer_spawn.wait_time = tiempo_entre_spawns
	timer_spawn.one_shot = false
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	add_child(timer_spawn)
	
	# Crear timer para iniciar oleadas
	timer_oleada = Timer.new()
	timer_oleada.wait_time = tiempo_entre_oleadas
	timer_oleada.one_shot = true
	timer_oleada.timeout.connect(_on_timer_oleada_timeout)
	add_child(timer_oleada)
	
	# Conectar los botones de game over (RUTA CORRECTA)
	if has_node("gameover/VBoxContainer/reiniciar"):
		$"gameover/VBoxContainer/reiniciar".pressed.connect(_on_reiniciar_pressed)
	if has_node("gameover/VBoxContainer/menu"):
		$"gameover/VBoxContainer/menu".pressed.connect(_on_menu_pressed)
	
	# Iniciar primera oleada después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	iniciar_oleada()

func _process(_delta):
	# Mover la torreta temporal con el mouse si está en modo compra
	if Global.modo_compra == true:
		if $torretas.get_child_count() > 0:
			var torreta_temporal = $torretas.get_child(0)
			torreta_temporal.global_position = get_global_mouse_position()
			
			# Hacer la torreta más visible y con efecto pulsante
			var pulse = (sin(Time.get_ticks_msec() / 200.0) * 0.1) + 0.9
			$torretas.modulate = Color(1, 1, 1, pulse)
			
			# Asegurar que esté por encima del GUI
			torreta_temporal.z_index = 100

func iniciar_oleada():
	if juego_terminado:
		return
		
	oleada_actual += 1
	esqueletos_spawneados = 0
	oleada_en_progreso = true
	carriles_usados_este_frame = []
	
	# Calcular nivel de dificultad (aumenta cada 5 oleadas)
	nivel_dificultad = int(oleada_actual / 5)
	
	# Aumentar spawns simultáneos progresivamente
	# Oleadas 1-4: 1 spawn, 5-9: 2 spawns, 10-14: 3 spawns, etc.
	max_spawns_simultaneos = 1 + int((oleada_actual - 1) / 5)
	max_spawns_simultaneos = min(max_spawns_simultaneos, 3)  # Máximo 3 simultáneos
	
	# Aumentar multiplicadores progresivamente cada 5 oleadas
	# Velocidad: +8% cada 5 oleadas (0.08 por nivel)
	multiplicador_velocidad = 1.0 + (nivel_dificultad * 0.08)
	
	# Vida: +15% cada 5 oleadas (0.15 por nivel)
	multiplicador_vida = 1.0 + (nivel_dificultad * 0.15)
	
	# Mostrar el número de oleada temporalmente
	if has_node("HUD/oleadas"):
		$HUD/oleadas.text = "Oleada " + str(oleada_actual)
		$HUD/oleadas.visible = true
		
		# Ocultar después de 3 segundos
		await get_tree().create_timer(3.0).timeout
		if has_node("HUD/oleadas"):
			$HUD/oleadas.visible = false
	
	# Aumentar dificultad progresivamente: +2 esqueletos por oleada
	var esqueletos_esta_oleada = esqueletos_por_oleada + (oleada_actual - 1) * 2
	
	# Iniciar spawn de esqueletos
	timer_spawn.start()

func _on_timer_spawn_timeout():
	if juego_terminado:
		timer_spawn.stop()
		return
		
	var esqueletos_esta_oleada = esqueletos_por_oleada + (oleada_actual - 1) * 2
	
	if esqueletos_spawneados < esqueletos_esta_oleada:
		# Limpiar carriles usados
		carriles_usados_este_frame = []
		
		# Spawnear múltiples esqueletos según el nivel
		var spawns_este_tick = min(max_spawns_simultaneos, esqueletos_esta_oleada - esqueletos_spawneados)
		
		for i in range(spawns_este_tick):
			spawnear_esqueleto_aleatorio()
			esqueletos_spawneados += 1
	else:
		# Oleada terminada, esperar para la siguiente
		timer_spawn.stop()
		oleada_en_progreso = false
		timer_oleada.start()

func _on_timer_oleada_timeout():
	# Iniciar siguiente oleada
	if not juego_terminado:
		iniciar_oleada()

func spawnear_esqueleto_aleatorio():
	if juego_terminado:
		return
	
	# Elegir un carril aleatorio que NO se haya usado en este frame
	var carril_aleatorio = null
	var intentos = 0
	while intentos < 10:
		carril_aleatorio = carriles[randi() % carriles.size()]
		if not carriles_usados_este_frame.has(carril_aleatorio):
			carriles_usados_este_frame.append(carril_aleatorio)
			break
		intentos += 1
	
	# Si no encontró un carril libre, usar cualquiera
	if carril_aleatorio == null:
		carril_aleatorio = carriles[randi() % carriles.size()]
	
	# Crear esqueleto
	var nuevo_esqueleto = esqueleto.instantiate()
	carril_aleatorio.add_child(nuevo_esqueleto)
	
	# Posicionar al inicio del path (progress_ratio = 0)
	nuevo_esqueleto.progress_ratio = 0.0
	
	# Decidir si es un esqueleto grande (20% de probabilidad desde oleada 5)
	var es_grande = false
	if oleada_actual >= 5:
		es_grande = randf() < 0.2  # 20% de probabilidad
	
	# Aplicar multiplicadores de dificultad al esqueleto
	if nuevo_esqueleto.has_method("aplicar_dificultad"):
		nuevo_esqueleto.aplicar_dificultad(multiplicador_velocidad, multiplicador_vida, es_grande)

func _reset():
	# Eliminar la torreta temporal
	for child in $torretas.get_children():
		child.queue_free()

func _on_perder_area_entered(area):
	# Verificar si es un esqueleto el que entró
	if area.get_parent() is PathFollow2D:
		game_over()

func _on_screen_time_timeout():
	# Incrementar el tiempo transcurrido cada segundo
	if not juego_terminado:
		tiempo_transcurrido += 1
		$HUD/Score.text = str(tiempo_transcurrido)

func game_over():
	if juego_terminado:
		return
	
	juego_terminado = true
	
	# Detener timers
	timer_spawn.stop()
	timer_oleada.stop()
	$HUD/ScreenTime.stop()
	$HUD.visible = false
	
	# Detener música del juego
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	if has_node("AudioStreamPlayer2"):
		$AudioStreamPlayer2.stop()
	
	# Pausar el juego
	get_tree().paused = true
	
	# Mostrar pantalla de game over
	$gameover.visible = true
	
	# Reproducir música de game over
	if $gameover.has_node("AudioStreamPlayer"):
		$gameover/AudioStreamPlayer.play()

func _on_reiniciar_pressed():
	# Reiniciar variables globales
	Global.reiniciar_variables()
	
	# Despausar el juego
	get_tree().paused = false
	
	# Recargar la escena
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	# Reiniciar variables globales
	Global.reiniciar_variables()
	
	# Despausar el juego
	get_tree().paused = false
	
	# Cambiar a la escena del menú
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
