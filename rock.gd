extends RigidBody2D

var screensize = Vector2.ZERO
var size
var radius
# 👇 is multiplied by size to set the Sprite2D scale, the collision 
# 👇 radius, and so on.
var scale_factor = 0.2

signal exploded

# 👇 calculate the correct collision size based on the rock’s size.
# 👇 position and size are already in use as class variables, so you have to use an underscore for 
# 👇 the function’sarguments to prevent conflict.
func start(_position, _velocity, _size):
	position = _position
	size = _size
	mass = 1.5 * size
	# print_debug(($Image.scale) == null)
	# 👇 Sprite2D changed to Image to get rid of nullptr error.
	# 👇 Seems like an Godot issue and renaming the name of the
	# 👇 node in the scene tree solves it as done here.
	$Image.scale = Vector2.ONE * scale_factor * size
	radius = int($Image.texture.get_size().x / 2 * scale_factor * size)
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionFrame.shape = shape
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)
	#👇 This will ensure the explosion is scaled to match the rock’s size.
	$Explosion.scale = Vector2.ONE * 0.75 * size

# We’re using physics_state for the parameter name rather than the default of state.
# This is to avoid confusion 👇 since state is already being used to track the player’s state.
func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
# To implement the wrap-around effect (teleport player from one end of screen to other end)
	var xform = physics_state.transform
	# The wrapf() function takes a value (the first argument) and “wraps” it between any min/max values 
	# you choose. So, if the value goes below 0, it becomes screensize.x, and vice versa.
	xform.origin.x = wrapf(xform.origin.x, 0 - radius, screensize.x + radius)
	# Including the rock's radius in calculation☝️👇 results in smoother looking teleportation
	xform.origin.y = wrapf(xform.origin.y, 0 - radius, screensize.y + radius)
	physics_state.transform = xform

func explode():
	# 👇 hide the rock 
	$CollisionFrame.set_deferred("disabled", true)
	$Image.hide()
	# 👇 and play the explosion
	$Explosion/AnimationPlayer.play("explosion")
	$Explosion.show()
	exploded.emit(size, radius, position, linear_velocity)
	# 👇 Resetting Rigidbody variables.
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	# 👇 waiting for animation to finish before removing the rock.
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()
