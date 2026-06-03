extends Tree

@onready var rel_request = $GetReleases
var download_icon = preload("res://images/downloads.png")
var versionsTree:Dictionary[String,TreeItem] = {}
@onready var root = self.create_item()

func _ready():
	self.hide_root = true
	var headers = [
		"User-Agent: GodotDownloader-v1.0",
        "Accept: application/vnd.github.v3+json"
	]
	rel_request.request("https://api.github.com/repos/GameabillityOnYt/obbying-revival-project/releases",headers)

func _on_get_releases_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK:
		var versions:Array = JSON.parse_string(body.get_string_from_utf8())
		versions.sort_custom(func(a,b):
			return a["published_at"] > b["published_at"]
			)
		
		for v in versions:
			var tag:String = v.tag_name
			var major = tag.split(".")[0].replace("v","").replace("V","").to_lower()
			if !(major in versionsTree.keys()):
				versionsTree[major] = self.create_item(root)
				versionsTree[major].set_text(0,"Versions " + major + ".X.X")
				versionsTree[major].set_selectable(0,false)
			
			var new = self.create_item(versionsTree[major])
			new.set_text(0,v.tag_name)
			new.add_button(0,download_icon,-1,false,"Download " + v.tag_name)
			new.set_selectable(0,false)
