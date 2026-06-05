extends Tree

var download_icon = preload("res://images/downloads.png")
var versionsTree:Dictionary[String,TreeItem] = {}
@onready var root = self.create_item()
var progress_bar_scn = preload("res://prefabs/LoadingUI.tscn")
var version_display_scn = preload("res://prefabs/VersionUI.tscn")

func start_download(tag:String,link:String):
	var new = progress_bar_scn.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var holder = get_parent().get_node("InstallList/Holder")
	holder.add_child(new)
	new.get_node("Label").text = tag
	await Shared.download_ver(tag,link,func(amnt:float):
		create_tween().tween_property(new.get_node("Progress"), "value", amnt*100,.1)
		pass)
	new.call_deferred("queue_free")
	
	get_parent().create_release_display(tag)
	Shared.local_releases.append({
			"tag": tag,
			"path": ProjectSettings.globalize_path("user://Versions/"+tag)
		})
	Shared.sort_local_releases()

func _ready():
	self.hide_root = true
	
	var versions:Array = Shared.releases
	versions.sort_custom(func(a,b):
		return a["published_at"] > b["published_at"]
		)
		
	for v in versions:
		var tag:String = v["tag_name"]
		var major = tag.split(".")[0].replace("v","").replace("V","").to_lower()
		if !(major in versionsTree.keys()):
			versionsTree[major] = self.create_item(root)
			versionsTree[major].set_text(0,"Versions " + major + ".X.X")
			versionsTree[major].set_selectable(0,false)
		
		var new = self.create_item(versionsTree[major])
		new.set_text(0,tag)
		new.add_button(0,download_icon,-1,false,"Download " + tag)
		new.set_selectable(0,false)
		new.set_meta("assets",v["assets"])
		new.set_meta("tag",tag)

func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var tag = item.get_meta("tag")
		if Shared.is_ver_installed(tag): return
		
		var assets = item.get_meta("assets")
		var link = ""
		match OS.get_name():
			"Linux": link = Shared.find_release_link(assets,"linux")
			"Windows": link = Shared.find_release_link(assets,"windows")
			"macOS": link = Shared.find_release_link(assets,"mac")
		
		await start_download(tag,link)
