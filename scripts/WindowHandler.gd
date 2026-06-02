extends Node

@export var dragging = false
var goal = Vector2i()
var exiting = false
var last_mouse_pos

func _ready():
	goal = get_window().position
	get_tree().scene_changed.connect(func():
		dragging = false
		pass)

func get_main() : 
	for child in get_tree().root.get_children():
		if child is Node2D: return child

func _process(_dt):
	var curr_pos = DisplayServer.mouse_get_position()
	
	if dragging:
		var vel = curr_pos-last_mouse_pos
		goal += vel
	
	last_mouse_pos = curr_pos
	var win_pos = get_window().position
	@warning_ignore("narrowing_conversion")
	get_window().position.x = move_toward(win_pos.x,goal.x,abs(goal.x-win_pos.x)/4)
	@warning_ignore("narrowing_conversion")
	get_window().position.y = move_toward(win_pos.y,goal.y,abs(goal.y-win_pos.y)/4)
	
	if Input.is_key_pressed(KEY_ESCAPE):
		_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if !exiting:
			exiting = true
			var main = get_main()
			print(main)
			create_tween().tween_property(main,"modulate",Color8(0,0,0,0),.5)
			await get_tree().create_timer(.55).timeout
			get_tree().quit()
