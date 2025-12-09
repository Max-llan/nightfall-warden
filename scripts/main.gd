extends Node2D
var torretas = preload("res://scenes/torreta.tscn")
var conteo = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$torretas.global_position = get_global_mouse_position()
	conteo = $torretas.get_child_count()
	if Global.modo_compra == true:
		if Input.is_action_just_pressed("click"):
			Global.modo_compra = false

func _on_button_pressed() -> void:
	if conteo == 0:
		Global.modo_compra = true
		var torreta = torretas.instantiate()
		$torretas.add_child(torreta)
		
	
func _reset():
	$torretas.get_child(0).queue_free()
