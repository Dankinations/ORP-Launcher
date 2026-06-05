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

func find_etag_header(hheaders:PackedStringArray):
	for x in hheaders:
		if "ETag: " in x:
			return x.replace("ETag: ","")

func find_release_by_tag(releases:Array,tag:String):
	for x in releases:
		if x["tag_name"] == tag:
			return x
	return null

func start_download(release):
	var assets = release["assets"]
	
	var download_link = ""
	match OS.get_name():
		"Linux": download_link = Shared.find_release_link(assets,"linux")
		"Windows": download_link = Shared.find_release_link(assets,"windows")
		"macOS": download_link = Shared.find_release_link(assets,"mac")
	
	await Shared.download_ver(release["tag_name"],download_link,func(amnt:float):
		bar.value = amnt*100
		pass)

func _ready():
	self.modulate = Color8(0,0,0,0)
	$Icon/Icon.position = Vector2(80,-80)
	$Icon.modulate = Color(0,0,0,0)
	create_tween().tween_property($Icon,"modulate",Color(1,1,1,1),.5)
	create_tween().tween_property($Icon/Icon,"position",Vector2(80,70),1)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	
	bar.indeterminate = true
	desc.text = "Loading data..."
	await Shared.load_data()
	
	ping.request("https://example.com/") # pinging to see if its online
	await ping.request_completed
	
	await get_tree().create_timer(1).timeout
	create_tween().tween_property(self,"modulate",Color(1,1,1,1),1)
	
	# Getting releases
	bar.indeterminate = true
	desc.text = "Fetching Releases..."
	
	if online:
		headers.append("If-None-Match: " + Shared.data.Etag)
		rel_request.request("https://api.github.com/repos/GameabillityOnYt/obbying-revival-project/releases",headers)
		await rel_request.request_completed
	
	var user = DirAccess.open("user://")
	if !user.dir_exists("Versions") and online: user.make_dir("Versions")
	elif !online: 
		$Title.text = "Can't Setup\noffline!"
		await get_tree().create_timer(2).timeout
		await WindowHandler._notification(NOTIFICATION_WM_CLOSE_REQUEST)
		return
	
	var fetch_local = func():
		var versions = DirAccess.open("user://Versions")
		versions.list_dir_begin()
		var curr
		while true:
			curr = versions.get_next()
			if curr == "": return
			if versions.current_is_dir():
				Shared.local_releases.append({
					"tag": curr,
					"path": "user://Versions".path_join(curr)
				})
			else:
				continue
		versions.list_dir_end()
	await fetch_local.call()
	
	# Creating the file if it doesnt exist
	desc.text = "Checking for file integrity..."
	
	if !FileAccess.file_exists("user://Versions/latest.txt") and online:
		var w = FileAccess.open("user://Versions/latest.txt",FileAccess.WRITE)
		w.store_string(Shared.releases[0]["tag_name"])
		w.close()
	
	# re-opening the file with reading priveleges too
	var r = FileAccess.open("user://Versions/latest.txt",FileAccess.READ)
	var latest:String = r.get_as_text(); r.close()
	Shared.latest = latest
	if !DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://Versions/%s"%latest)): latest = ""
	
	if latest != Shared.releases[0]["tag_name"] and online:
		var w = FileAccess.open("user://Versions/latest.txt",FileAccess.WRITE)
		latest = Shared.releases[0]["tag_name"]
		w.store_string(latest)
		w.close()
		
		desc.text = "Downloading latest version...\n(%s)" % latest
		bar.indeterminate = false
		await start_download(Shared.releases[0])
		Shared.local_releases.append({
			"tag" : latest,
			"path": "user://Versions".path_join(latest)
		})
	
	Shared.sort_local_releases()
	
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
	$Icon.top_level = false
	create_tween().tween_property(self,"modulate",Color(0,0,0,0),.5)
	await get_tree().create_timer(.75).timeout
	get_tree().change_scene_to_file("res://Main.tscn")

func _process(_delta: float) -> void:
	WindowHandler.dragging = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _on_request_completed(result: int, code: int, gheaders: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS: 
		if code == 200:
			Shared.releases = JSON.parse_string(body.get_string_from_utf8())
			var found = find_etag_header(gheaders)
			Shared.data.Etag = found
		elif code == 304:
			print("Nothing changed in releases!")
	else: push_error("Connection dropped!"); online = false

func _on_ping_request_completed(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS: online = true
