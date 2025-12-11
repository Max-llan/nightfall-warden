extends Node

var ubicacion = Vector2(0,0)
var comprovacion = false
var modo_compra = false

# Sistema de monedas
var monedas = 200
var costo_torreta = 100
var valor_moneda = 50

func agregar_monedas(cantidad: int):
	monedas += cantidad
	actualizar_ui_dinero()

func gastar_monedas(cantidad: int) -> bool:
	if monedas >= cantidad:
		monedas -= cantidad
		actualizar_ui_dinero()
		return true
	else:
		return false

func actualizar_ui_dinero():
	# Actualizar el label del GUI
	var main = get_tree().current_scene
	if main:
		var gui = main.get_node_or_null("gui/GUI")
		if gui and gui.has_node("header/coin"):
			var label_coin = gui.get_node("header/coin")
			label_coin.text = "$" + str(monedas)

func reiniciar_variables():
	# Resetear variables al reiniciar el juego
	monedas = 200
	modo_compra = false
	comprovacion = false
	ubicacion = Vector2(0, 0)
