extends Sprite2D

@export var scroll_speed = Vector2(20,20)

func _physics_process(delta: float) -> void:
	region_rect.position += scroll_speed * delta
