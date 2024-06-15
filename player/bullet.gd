extends Area2D

@export var speed = 1000

var velocity = Vector2.ZERO

# call 👇 to spawn a new bullet
func start(_transform):
# Over here, ☝️ will have position/rotation of ship
	transform = _transform
	velocity = transform.x * speed

func _process(delta: float) -> void:
	position += velocity * delta

# 👇 To delete bullets that goes off-screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# 👇 To detect whenever a bullet hits a rock
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		body.explode() # This methode will be defined in rocks scripts
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.take_damage(1)
