extends Area2D

# 👇 Variables to set enemy bullet spped and damage in inspector
@export var speed = 1000
@export var damage = 15

#  👇 To specify a position and direction for the bullet.
func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()

# 👇 The enemy’s bullets should also do damage
func _on_body_entered(body):
	if body.name == "Player":
		body.shield -= damage
	queue_free()

func _process(delta: float) -> void:
	position += transform.x * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
