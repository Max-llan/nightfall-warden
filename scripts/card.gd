extends Control

# Datos de la torreta que representa esta card
@export var costo: int = 100
@export var nombre_torreta: String = "Torreta Básica"
@export var torreta_scene: PackedScene

var button: Button
var label_costo: Label

func _ready() -> void:
	# Obtener referencias a los nodos
	button = $button
	label_costo = $button/Label
	
	# Configurar el texto del costo
	actualizar_costo()
	
	# Conectar señal del botón
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)
	
	# Configurar mouse filter para que no bloquee clicks
	mouse_filter = Control.MOUSE_FILTER_PASS

func actualizar_costo():
	if label_costo:
		label_costo.text = "$" + str(costo)
		
		# Cambiar color según si puede comprar o no
		if Global.monedas >= costo:
			label_costo.add_theme_color_override("font_color", Color(0, 1, 0))
			# Botón habilitado visualmente
			if button:
				button.modulate = Color(1, 1, 1, 1)
		else:
			label_costo.add_theme_color_override("font_color", Color(1, 0, 0))
			# Botón deshabilitado visualmente
			if button:
				button.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _process(_delta: float) -> void:
	# Actualizar el color del costo continuamente
	actualizar_costo()

func _on_button_pressed() -> void:
	# Verificar si ya está en modo compra
	if Global.modo_compra:
		return
	
	# Verificar si tiene suficiente dinero
	if Global.monedas >= costo:
		# Efecto visual de click
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		
		# Activar modo compra
		Global.modo_compra = true
		
		# Obtener el nodo main y crear la torreta temporal
		var main = get_tree().current_scene
		if main and main.has_node("torretas"):
			# Limpiar cualquier torreta temporal anterior
			var torretas_node = main.get_node("torretas")
			for child in torretas_node.get_children():
				child.queue_free()
			
			# Crear nueva torreta temporal
			var torreta_scene_load = preload("res://scenes/torreta.tscn")
			var nueva_torreta = torreta_scene_load.instantiate()
			torretas_node.add_child(nueva_torreta)
			nueva_torreta.global_position = get_global_mouse_position()
			
			# Hacer la torreta más visible (sin transparencia al inicio)
			torretas_node.modulate = Color(1, 1, 1, 0.8)
	
