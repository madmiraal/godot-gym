extends Node2D

export (bool) var loop = false

onready var player_scene = preload("res://2DAssets/RigidBody Player.tscn")
onready var platform_scene = preload("res://2DAssets/RigidBody Platform.tscn")

var player
var platform
var test_id = 0
var angle_steps = 8
var player_position
var player_linear
var player_angular = 0
var platform_position = Vector2(512, 250)
var platform_linear = Vector2(0, 0)
var platform_angular = 0

func _input(event):
	if event.is_action_pressed("ui_accept") and $Complete.visible:
		$Complete.visible = false
		$Timer.start()
		prepare_next_test()
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _ready():
	prepare_next_test()

func update_labels():
	$"Test".text = "Test " + str(test_id)
	$"Player Linear".text = "Linear velocity:  " + str(player_linear)
	$"Player Angular".text = "Angular velocity: " + str(player_angular)
	$"Platform Linear".text = "Linear velocity:  " + str(platform_linear)
	$"Platform Angular".text = "Angular velocity: " + str(platform_angular)
	
func start_test():
	player = player_scene.instance()
	platform = platform_scene.instance()
	player.position = platform_position + player_position
	player.linear_velocity = player_linear
	player.angular_velocity = player_angular
	platform.position = platform_position
	platform.linear_velocity = platform_linear
	platform.angular_velocity = platform_angular
	add_child(player)
	add_child(platform)

func prepare_next_test():
	var player_angle = (test_id % angle_steps) * 2 * PI / angle_steps
	var player_x = sin(player_angle)
	var player_y = -cos(player_angle)
	player_position = Vector2(player_x, player_y) * 100
	player_linear = -player_position
	if abs(player_position.y) < 0.1:
		player_position.x *= 2.5
	if test_id % 8 == 0:
		if test_id == 8:
			player_angular = .5
		if test_id == 16:
			player_angular = 0
			platform_angular = .1
		if test_id == 24:
			platform_angular = 0
			test_id = 0
			if not loop:
				complete()
				return
	test_id += 1
	update_labels()
	start_test()

func end_test():
	player.free()
	platform.free()

func complete():
	$Complete.visible = true
	$Timer.stop()
	
func _on_Timer_timeout():
	end_test()
	prepare_next_test()

