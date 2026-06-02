extends Sprite2D

var maxx = 0
var maxy = 0

@onready var RNG = RandomNumberGenerator.new()

func _process(_delta):
	var goal = Vector2(maxx,maxy)
	var dist = region_rect.position.distance_to(goal)
	region_rect.position = region_rect.position.move_toward(goal,max(dist/64,1.25)/32)
	
	if region_rect.position.x == maxx:
		maxx = round(RNG.randf()*(1633-region_rect.size.x))
	if region_rect.position.y == maxy:
		maxy = round(RNG.randf()*(980-region_rect.size.y))
