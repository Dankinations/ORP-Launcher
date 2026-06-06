extends Node2D

var selected_ver = Shared.latest
var version_display_scn = preload("res://prefabs/VersionUI.tscn")

func create_release_display(x):
	var display = version_display_scn.instantiate()
	display.name = x
	get_node("VersionsList/Holder").add_child(display)
	var label:RichTextLabel = display.get_node("VersionLabel")
	label.text = x
	label.scale = Vector2.ONE*clamp(.5-label.get_total_character_count()*.02,.4,1.0)

func _ready():
	for x in Shared.local_releases:
		create_release_display(x["tag"])
	
	self.modulate = Color8(0,0,0,0)
	get_window().size = $BG.region_rect.size
	@warning_ignore("integer_division")
	var pos = Vector2(DisplayServer.screen_get_size(get_window().current_screen)/2-get_window().size/2)
	WindowHandler.goal = pos
	WindowHandler.smooth_win_pos = pos
	create_tween().tween_property(self,"modulate",Color8(255,255,255,255),.5)
	
	var ext = "exe"
	match OS.get_name():
		"Linux": ext = "x86_64"
		"Windows": ext = "exe"
	
	$Play.pressed.connect(func():
		var path = ProjectSettings.globalize_path("user://Versions/"+selected_ver+"/orp."+ext)
		if OS.get_name() == "Linux": OS.execute("chmod",["+x", path])
		if OS.get_name() == "Windows": path = path.replace("/","\\")
		var result = OS.create_process(path,[])
		pass)

func _process(_dt: float) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): WindowHandler.dragging = false

func _on_top_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			WindowHandler.dragging = event.pressed

func _on_holder_child_entered_tree(p: Node) -> void:
	var select:Button = p.get_node("Select")
	select.pressed.connect(func():
		for x in get_node("VersionsList/Holder").get_children(true):
			x.get_node("Select").text = "Select"
		select.text = "Selected"
		selected_ver = p.get_node("VersionLabel").text
		pass)
	var delete:TextureButton = p.get_node("Delete")
	
	delete.pressed.connect(func():
		var to_remove = ProjectSettings.globalize_path("user://Versions/"+p.get_node("VersionLabel").text)
		if OS.get_name() == "Windows": to_remove = to_remove.replace("/","\\")
		OS.move_to_trash(to_remove)
		p.call_deferred("queue_free")
		pass)
