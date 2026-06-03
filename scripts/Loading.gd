extends Node2D

var last_mouse_pos
var exiting = false

func _ready():
	get_window().popup()
	
	await get_tree().create_timer(2).timeout
	$Title.text = "Done"
	
	var mat = $ColorRect.material as ShaderMaterial
	create_tween().tween_property(mat,"shader_parameter/iris_size",2,.5)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)
		
	await get_tree().create_timer(2).timeout
	create_tween().tween_property(self,"modulate",Color8(0,0,0,0),.5)
	
	await get_tree().create_timer(.75).timeout
	get_tree().change_scene_to_file("res://Main.tscn")

func _process(_delta: float) -> void:
	WindowHandler.dragging = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
