extends Node2D

func _ready():
	self.modulate = Color8(0,0,0,0)
	get_window().size = $BG.region_rect.size
	@warning_ignore("integer_division")
	var pos = Vector2(DisplayServer.screen_get_size(get_window().current_screen)/2-get_window().size/2)
	WindowHandler.goal = pos
	WindowHandler.smooth_win_pos = pos
	create_tween().tween_property(self,"modulate",Color8(255,255,255,255),.5)

func _process(_dt: float) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): WindowHandler.dragging = false

func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			WindowHandler.dragging = event.pressed
