extends RigidBody2D

# 👇 how fast the ship can accelerate 
@export var engine_power = 500
# 👇 how fast the ship can turn
@export var spin_power = 8000
# 👇 Force being applied by the engine
var thrust = Vector2.ZERO
# 👇 Torque or rotational force
var rotation_dir = 0
# 👇 To know the size of the screen
var screensize = Vector2.ZERO
# 👇 To send signal to reduce lives
signal lives_changed
# 👇 To send signal to change player state
signal dead
# 👇 To send signal to shield level in HUD
signal shield_changed
# 👇 Maximum rate of shield
@export var max_shield = 100.0
# 👇 Rate of shield regenerated
@export var shield_regen = 5.0

var reset_pos = false
# 👇 Adding a setter for the "lives" variable, so that whenever the value of "lives" changes,
# 👇 the set_lives function will be called. This lets you automatically emit the signal as 
# 👇 well as checking when it reaches 0.
var lives = 0: set = set_lives

# 👇 Function to set lives everytime the number of "lives" changes
func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)
	# 👇 If the player’s shield runs out and they lose a life, you should reset the shield 
	# 👇 to its maximum. 
	shield = max_shield

# 👇 This function is called by Main when a new game starts
func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)

### 👇👇👇 Declarations for shooting laser
@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
var can_shoot = true

###### Creating the skeleton of the FSM implementation ######
enum { INIT, ALIVE, INVULNERABLE, DEAD} 
# ☝️convenient way to create a set of constants. 
# It is similar to 👇
# const INIT = 0
# const ALIVE = 1
# const INVULNERABLE = 2
# const DEAD = 3
var state = INIT # Initial state to be set by default

func _ready() -> void:
	screensize = get_viewport_rect().size
	change_state(ALIVE)
	# 👇 Starts the timer after every laser fire
	$GunCooldown.wait_time = fire_rate

func change_state(new_state):
# To change the state of the player, just pass it the value of the new state.
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			# 👇 The modulate.a property of a sprite sets its alpha channel (transparency).
			# 👇 Setting it to 0.5 makes it semi-transparent.
			$Sprite2D.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			# 👇 Setting it to 0.5 makes it solid.
			$Sprite2D.modulate.a = 1.0
		# 👇 Enabled when the player runs out of lives and game ends
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			# 👇 Setting it to 0.5 makes it semi-transparent.
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
			# 👇 If player dies while pressing thrust, the audio may get stuck. To stop it playing 🤌
			if $EngineSound.playing:
				$EngineSound.stop()
	state = new_state

func _process(delta: float) -> void:
	get_input()
	# 👇 To regenerate the shield each frame.
	shield += shield_regen + delta
	
func get_input():
# ☝️ captures the key actions and sets the ship’s thrust on or off.
	$Exhaust.emitting = false
	# ☝️ Turn off the Exhaust Particle effect by default
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	if Input.is_action_pressed("thrust"):
		# 👇 Turn on the Exhaust particle effect
		$Exhaust.emitting = true
		thrust = transform.x * engine_power
		# 👇 Only plays the sound if it isn't already playing or else it would always play from start
		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()
	# 👇rotation_dir will be clockwise, counter-clockwise, or zero
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	# Here, Input.get_axis ☝️ returns a value based on two inputs, representing negative and positive values.
	
	# If button to shoot is pressed 👇
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
	
func shoot():
	if state == INVULNERABLE:
		return
	# 👇 done so that shoot() is no loner called
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	# 👇 add the new bullet as a child of whatever node is the root of the scene tree.
	get_tree().root.add_child(b)
	# 👇 called to give it the muzzle node’s global transform.
	b.start($Muzzle.global_transform)
	# 👇 plays the laser sound
	$LaserSound.play()

func _physics_process(delta: float) -> void:
# when using physics bodies, their movement and related functions should always 
# be called in_physics_process(). Here, you can apply the forces set by the inputs to actually move the body.
	constant_force = thrust
	constant_torque = rotation_dir * spin_power

# We’re using physics_state for the parameter name rather than the default of state.
# This is to avoid confusion 👇 since state is already being used to track the player’s state.
func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
# To implement the wrap-around effect (teleport player from one end of screen to other end)
	var xform = physics_state.transform
	# The wrapf() function takes a value (the first argument) and “wraps” it between any min/max values 
	# you choose. So, if the value goes below 0, it becomes screensize.x, and vice versa.
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	# Resetting the player by setting its position back to the center of the screen.
	if reset_pos:
		physics_state.transform.origin = screensize/2
		reset_pos = false
	
# 👇 once the timer is up, allow player to shoot again
func _on_gun_cooldown_timeout() -> void:
	can_shoot = true


func _on_invulnerability_timer_timeout() -> void:
	change_state(ALIVE)

# 👇 Signal to check if the body entered is among "rocks"
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("rocks"):
		shield -= body.size * 25
		body.explode()
		# 👇 Moved to set_shield() function
		# body.explode()
		# lives = lives - 1
		# explode()

# 👇 Function to trigger explosion
func explode():
	# 👇 Make Explosion Scene visible
	$Explosion.show()
	# 👇 Start playing the animation player using AnimationPlayer node
	$Explosion/AnimationPlayer.play("explosion")
	# 👇 Wait for the animation to finish
	await $Explosion/AnimationPlayer.animation_finished
	# 👇 Hide the Explosion Scene
	$Explosion.hide()

####		Setting up shield		####
# The shield variable works similarly to lives, emitting a signal whenever it changes. Since the 
# value will be added to by the shield’s regeneration, you need to make sure it doesn’t go above the 
# max_shield value. Then, when you emit the shield_changed signal, you pass the ratio of 
# shield / max_shield rather than the actual value. This way, the HUD’s display doesn’t need to 
# know anything about how big the shield actually is, just its percentage.
var shield = 0: set = set_shield

# 👇 Setter Function to set the value of shield throughout the game
func set_shield(value):
	# 👇 Choose a random value of the shield in the begining
	value = min(value, max_shield)
	shield = value
	# 👇 Pass the ratio of shield / max_shield rather than the actual value to HUD Display
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		# 👇 Once the shield is 0, reduce a life and trigger explosion animation.
		lives -= 1		
		explode()

