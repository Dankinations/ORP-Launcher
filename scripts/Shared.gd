extends Node

var releases = {}

func unzip(zip:String):
	var reader := ZIPReader.new()
	var err := reader.open(zip)
	if err != OK: push_error("Couldn't open zip correctly!"); return false
	
	var files := reader.get_files()
	
	var first_entry = files[0]
	var root_folder = ""
	
	if first_entry.ends_with("/"):
		root_folder = first_entry

	var is_nested = true
	for file_path in files:
		if not file_path.begins_with(root_folder):
			is_nested = false
			break
	
	for path in files:
		var dest = zip.get_base_dir().path_join(path)
		if is_nested and root_folder != "":
			dest = dest.replace(root_folder,"")
		if path.ends_with("/"): DirAccess.make_dir_recursive_absolute(zip.get_base_dir()); continue
		if !DirAccess.dir_exists_absolute(dest.get_base_dir()): DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
		var file = FileAccess.open(dest,FileAccess.WRITE)
		if file:
			file.store_buffer(reader.read_file(path))
			file.close()
	reader.close()
	print("Unzipped everything to " + zip.get_base_dir())
	DirAccess.remove_absolute(zip)
	return true

func download_ver(tag:String,asset:String,update_progress:Callable):
	var headers = [
		"User-Agent: GodotDownloader-v1.0",
		"Accept: application/vnd.github.v3+json"
	]
	
	var global = ProjectSettings.globalize_path("user://Versions/"+tag)
	if DirAccess.dir_exists_absolute(global): return
	DirAccess.make_dir_absolute("user://Versions/"+tag)
	
	var timer = Timer.new()
	timer.wait_time = .01
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	
	var installer = HTTPRequest.new()
	installer.download_file = global.path_join(tag+".zip")
	timer.timeout.connect(func():
		var installed = float(installer.get_downloaded_bytes())
		var total = float(installer.get_body_size())
		if total > 0: update_progress.call_deferred(installed/total)
		pass)
	add_child(installer)
	
	installer.request(asset,headers)
	var results = await installer.request_completed
	var success = results[0] == HTTPRequest.RESULT_SUCCESS
	if success: 
		print("Sucessfully installed!")
		unzip(installer.download_file)
			
	
	timer.call_deferred("queue_free")
	installer.call_deferred("queue_free")
