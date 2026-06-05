extends Node

@export var dragging = false
var goal = Vector2()
var exiting = false
var last_mouse_pos

var win_speed = 1.0
var smooth_win_pos = Vector2.ZERO

func _ready():
	goal = Vector2(get_window().position)
	smooth_win_pos = goal
	get_tree().scene_changed.connect(func():
		dragging = false
		pass)

func get_main() : 
	for child in get_tree().root.get_children():
		if child is Node2D: return child

func _process(dt: float) -> void:
	var curr_pos = DisplayServer.mouse_get_position()
	
	if dragging:
		var vel = Vector2(curr_pos-last_mouse_pos)
		goal += vel
	
	last_mouse_pos = curr_pos
	var target = Vector2(goal)
	smooth_win_pos = smooth_win_pos.lerp(target, 1.0 - exp(-15 * dt))
	
	get_window().position.x = smooth_win_pos.x
	get_window().position.y = smooth_win_pos.y
	
	if Input.is_key_pressed(KEY_ESCAPE):
		_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _exit_tree() -> void:
	Shared.save_data()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if !exiting:
			exiting = true
			var main = get_main()
			create_tween().tween_property(main,"modulate",Color8(0,0,0,0),.5)
			await get_tree().create_timer(.55).timeout
			get_tree().quit()
