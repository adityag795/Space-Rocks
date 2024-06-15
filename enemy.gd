extends Area2D

# 👇 Making these variables editable in the inspector
@export var bullet_scene : PackedScene
@export var speed = 150
@export var rotation_speed = 120
@export var health = 3
# 👇 Creates a Pathfollow2D node to store a "Path2D" data
var follow = PathFollow2D.new()
# 👇 Adding a variable for some random variation to the bullet
@export var bullet_spread = 0.2
# 👇 To store location of player ship
var target = null

func _ready() -> void:
	# 👇 Randomly choosing the sprite among the Hframe
	$Sprite2D.frame = randi() % 3
	# 👇 Randomly choosing the path that enemy will follow from the EnemyPath Scene
	var path = $EnemyPaths.get_children() [randi () % $EnemyPaths.get_child_count()]
	
	path.add_child(follow)
	# 👇 "PathFollow2D" node automatically moves along a parent Path2D. By default, it loops around the
	# 👇 path when it reaches the end, so you need to set that to "false" to disable it.
	follow.loop = false

func _physics_process(delta: float) -> void:
	# 👇 Keeps the sprite rotating
	rotation += deg_to_rad(rotation_speed) * delta
	# 👇 Updates the value of follow along the "Path2D" with "speed" and "delta"
	follow.progress += speed * delta
	# 👇 Updates the position of the sprite
	position = follow.global_position
	# 👇 Once the path to be traverssed is complete, delete the Gameobject.
	# 👇 You can detect the end of the path when progress is greater than the total path length.
	# 👇 "progress_ratio" varies from 0 to 1 over the lengthof the path.
	if follow.progress_ratio >= 1:
		queue_free()

# 👇 This will shoot a given number of bullets, n, with delay seconds between them. You can 
# 👇 call this instead when the cooldown triggers.
func _on_gun_cooldown_timeout() -> void:
	#shoot()
	# 👇 This will shoot a pulse of 3 bullets with 0.15 seconds between them. Tough to dodge!
	shoot_pulse(3, 0.15)

func shoot():
	# 👇 Plays the laser sound
	$LaserSound.play()
	# 👇 Stores the direction to turn for position of player
	var dir = global_position.direction_to(target.global_position)
	# 👇 Rotates the ship for aiming & firing bullets at player
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	# 👇 Instantiates bullet scene
	var b = bullet_scene.instantiate()
	# 👇 Adds the bullet scene to the main scene tree
	get_tree().root.add_child(b)
	# 👇 Sets the bullet to move towards the player
	b.start(global_position, dir)

# 👇 Making enemy shoot in pulses or multiple rapid shots
func shoot_pulse(n, delay):
	for i in n:
		shoot()
		await get_tree().create_timer(delay).timeout

# 👇 Is called by Player bullet to reduce enemy health and play flash animation
func take_damage(amount):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()

# 👇 Triggers explosion scene after hiding enemy sprite and disabling its collision shape
func explode():
	# 👇 Play explosion sound
	$ExplosionSound.play()
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()

# 👇 Connecting the enemy’s body_entered signal so that the enemy will explode if the player runs into it
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("rocks"):
		return
	explode()
	# 👇 Running into the enemy should damage the player
	body.shield -= 50
