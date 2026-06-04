extends Node2D

var online = false
@onready var rel_request = $GetReleases
@onready var ping = $Ping
var exiting = false
var headers = [
		"User-Agent: GodotDownloader-v1.0",
		"Accept: application/vnd.github.v3+json"
	]
@onready var bar = $Progress
@onready var desc = $ProgressDesc

func find_release_link(assets:Array,find:String):
	for x in assets:
		var n:String = x["name"]
		if n.to_lower().find(find.to_lower()): return x["browser_download_url"]
	return null

func find_release_by_tag(releases:Array,tag:String):
	for x in releases:
		if x["tag_name"] == tag:
			return x
	return null

func start_download(release):
	var assets = release["assets"]
	
	var download_link = ""
	match OS.get_name():
		"Linux": download_link = find_release_link(assets,"linux")
		"Windows": download_link = find_release_link(assets,"windows")
		"macOS": download_link = find_release_link(assets,"mac")
	await Shared.download_ver(release["tag_name"],download_link,func(amnt:float):
		bar.value = amnt*100
		pass)

func _ready():
	ping.request("https://example.com/") # pinging to see if its online
	await ping.request_completed
	
	# Getting releases
	bar.indeterminate = true
	desc.text = "Fetching Releases..."
	if online:
		rel_request.request("https://api.github.com/repos/GameabillityOnYt/obbying-revival-project/releases",headers)
		await rel_request.request_completed
	
	var user = DirAccess.open("user://")
	if !user.dir_exists("Versions") and online: user.make_dir("Versions")
	elif !online: 
		$Title.text = "Can't Setup\noffline!"
		await get_tree().create_timer(2).timeout
		await WindowHandler._notification(NOTIFICATION_WM_CLOSE_REQUEST)
		return
	
	# Creating the file if it doesnt exist
	desc.text = "Checking for file integrity..."
	
	if !FileAccess.file_exists("user://Versions/latest.txt") and online:
		var w = FileAccess.open("user://Versions/latest.txt",FileAccess.WRITE)
		w.store_string(Shared.releases[0]["tag_name"])
		w.close()
	
	# re-opening the file with reading priveleges too
	var r = FileAccess.open("user://Versions/latest.txt",FileAccess.READ)
	var latest:String = r.get_as_text(); r.close()
	
	if !DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://Versions/%s"%latest)):
		latest = ""
	
	if latest != Shared.releases[0]["tag_name"] and online:
		var w = FileAccess.open("user://Versions/latest.txt",FileAccess.WRITE)
		latest = Shared.releases[0]["tag_name"]
		w.store_string(latest)
		w.close()
		
		desc.text = "Downloading latest version...\n(%s)" % latest
		bar.indeterminate = false
		await start_download(Shared.releases[0])
	
	await get_tree().create_timer(2).timeout
	bar.indeterminate = false
	bar.value = 0
	desc.text = ""
	$Title.text = "Done" if online else "Offline"
	
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

func _on_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS: Shared.releases = JSON.parse_string(body.get_string_from_utf8())
	else: push_error("Connection dropped!"); online = false
func _on_ping_request_completed(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS: online = true
