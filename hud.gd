extends CanvasLayer

# 👇 emit the start_game signal when the player clicks the StartButton. 
signal start_game

# 👇 Assigning referenes of all the nodes located under containers after nodes are ready (when _ready() runs)
@onready var lives_counter = $MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var message = $VBoxContainer/Message
@onready var start_button = $VBoxContainer/StartButton
@onready var shield_bar = $MarginContainer/HBoxContainer/ShieldBar

# 👇 In addition to the green bar, you also have red and yellow bars in the assets folder. Loading 
# 👇 the textures in this way makes themeasier to access later in the script when you want to assign 
# 👇 the appropriate image to the bar.
var bar_textures = {
	"green" : preload("res://assets/bar_green_200.png"),
	"yellow": preload("res://assets/bar_yellow_200.png"),
	"red": preload("res://assets/bar_red_200.png")
}

# 👇 To change the shield bar’s color as the value decreases. 
func update_shield(value):
	shield_bar.texture_progress = bar_textures["green"]
	if value < 0.4:
		shield_bar.texture_progress = bar_textures["red"]
	elif value < 0.7:
		shield_bar.texture_progress = bar_textures["yellow"]
	shield_bar.value = value

#####	👇👇	Functions to handle updating the displayed information			#####
func show_message(text):
	message.text = text
	message.show()
	$Timer.start()

func update_score(value):
	score_label.text = str(value)

func update_lives(value):
	for item in 3:
		# Makes lives image visible as long as values received is greater than loop variable.
		lives_counter[item].visible = value > item

##### 	👇👇	Function to handle the end of the game			#####
func game_over():
	show_message("Game Over")
	await $Timer.timeout
	start_button.show()

#### 👇 Signals 👇 ####
func _on_start_button_pressed() -> void:
	start_button.hide()
	start_game.emit()

func _on_timer_timeout() -> void:
	message.hide()
	message.text = ""
