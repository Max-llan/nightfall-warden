extends Control

var label_coin: Label

func _ready() -> void:
	# Obtener referencia al label de monedas
	label_coin = $header/coin
	
	# Configurar mouse filter para no bloquear clicks
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Actualizar el dinero inicial
	actualizar_dinero()

func _process(_delta: float) -> void:
	# Actualizar el display de dinero constantemente
	actualizar_dinero()

func actualizar_dinero():
	if label_coin:
		label_coin.text = "$" + str(Global.monedas)
