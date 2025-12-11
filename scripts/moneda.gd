extends Area2D

var valor = 50
var tiempo_vida = 12.0
var puede_recolectar = true
var esta_siendo_recolectada = false

func _ready():
	# Configurar para que esté encima de todo
	z_index = 4096
	z_as_relative = false
	
	# Configurar capas de colisión
	collision_layer = 8
	collision_mask = 0
	
	# Hacer clickeable
	input_pickable = true
	
	# Verificar CollisionShape2D
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = false
	
	# Animación de aparición
	modulate.a = 0
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Reproducir animación
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")
	
	# Timer para desaparecer
	await get_tree().create_timer(tiempo_vida).timeout
	if puede_recolectar and not esta_siendo_recolectada:
		desaparecer()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		# SOLO detectar cuando SE PRESIONA el botón, no cuando se suelta
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if puede_recolectar and not esta_siendo_recolectada:
				recolectar()
				get_viewport().set_input_as_handled()

func recolectar():
	# Verificar ANTES de hacer cualquier cosa
	if esta_siendo_recolectada or not puede_recolectar:
		return
	
	# Marcar INMEDIATAMENTE como recolectada
	esta_siendo_recolectada = true
	puede_recolectar = false
	input_pickable = false
	
	# Sumar 50
	Global.agregar_monedas(50)
	actualizar_label_dinero()
	
	# Eliminar inmediatamente
	queue_free()

func actualizar_label_dinero():
	var main = get_tree().current_scene
	if main:
		var texture_rect = main.get_node_or_null("TextureRect")
		if texture_rect:
			var label_dinero = texture_rect.get_node_or_null("dinero")
			if label_dinero:
				label_dinero.text = "$" + str(Global.monedas)

func desaparecer():
	if esta_siendo_recolectada:
		return
	
	puede_recolectar = false
	
	# Animación de desaparición
	for i in range(3):
		modulate.a = 0.3
		await get_tree().create_timer(0.15).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.15).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	queue_free()

func _on_mouse_entered():
	if puede_recolectar and not esta_siendo_recolectada:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)

func _on_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if puede_recolectar and not esta_siendo_recolectada:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
