extends Node2D

@export var rock_scene : PackedScene
@export var enemy_scene : PackedScene

var screensize = Vector2.ZERO

#####	👇👇	UI Code			#####
var level = 0
var score = 0
var playing = false

func _ready() -> void:
	# 👇 get the screensize so that you can pass it to the rocks 
	# 👇 when they’re spawned.
	screensize = get_viewport().get_visible_rect().size
	#for i in 3:
		#spawn_rock(3)

# 👇 When called with only a size parameter, it picks a random position along the RockPath 
# 👇 and a random velocity.
func spawn_rock(size, pos=null, vel=null):
# This function lets you spawn the smaller rocks at the location 
# of the explosion by specifying their properties.
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	# 👇 This connects the rock’s signal to a function in Main.
	r.exploded.connect(self._on_rock_exploded)

func _on_rock_exploded(size, radius, pos, vel):
	# 👇 Play explosion sound
	$ExplosionSound.play()
	# 👇 create two new rocks unless the rock that was just destroyed was of size 1 (thesmallest size)
	if size <= 1:
		return
	# 👇 loop variable ensures that the two new rocks travel in opposite directions(that is, one’s 
	# 👇 velocity will be negative).
	for offset in [-1, 1]:
		# 👇 variable finds the vector between the player and the rock, then uses orthogonal() to get 
		# 👇 a vector that’s perpendicular to ensure that the new rocks don't fly straight.
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)

#####	👇👇	function to handle starting a new game		#####
func new_game():
	# 👇 To start the music
	# $Music.play()
	# 👇 remove any old rocks from previous game
	get_tree().call_group("rocks", "queue_free")
	# 👇 Resets the score and level
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true


# 👇 Call this function every time the level changes. It announces the level number 
# 👇 and spawns a number of rocks to match.
func new_level():
	# 👇 Play levelup sound
	$LevelupSound.play()
	level += 1
	$HUD.show_message("Wave %s" % level)
	for i in level:
		spawn_rock(3)
	$EnemyTimer.start(randf_range(5, 10))

# 👇 To detect when the level has ended
func _process(delta: float) -> void:
	if not playing:
		return
	# 👇 Once the player destroys all rocks, they'll advance 
	# 👇 to the next level
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()

# 👇 To handle what happens when the game ends
func game_over():
	# 👇 To stop the music
	# $Music.stop()
	playing = false
	$HUD.game_over()
# 👇This code detects pressing the key and toggles the tree’s paused state to the 
# 👇opposite of its currentstate. 
func _input(event):
	if event.is_action_pressed("Pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		# 👇 displays Paused on the screen so that it doesn’t just appear that the game has frozen
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()

# 👇 This code instances the enemy whenever EnemyTimer times out. You don’t want another enemy for 
# 👇 a while, so the timer is restarted with a longer delay.
func _on_enemy_timer_timeout() -> void:
	var e = enemy_scene.instantiate()
	add_child(e)
	# 👇 Sets the target variable in enemy script to player
	e.target = $Player
	$EnemyTimer.start(randf_range(20, 40))
