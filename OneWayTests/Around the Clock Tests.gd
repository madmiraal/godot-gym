extends Node2D

export (int) var direction_step = 45
export (int) var platform_rotation_step = 15
export (int) var player_rotation_step = 360
export (bool) var stop_on_failure
export (bool) var print_failure = false
export (bool) var loop = false

onready var rigid_player_scene = preload("res://2D Assets/RigidBody Player.tscn")
onready var kinematic_player_scene = preload("res://2D Assets/KinematicBody Player.tscn")
onready var long_platform_scene = preload("res://2D Assets/One-Way Blocks/StaticBody Platform.tscn")
onready var short_platform_scene = preload("res://2D Assets/One-Way Blocks/StaticBody Block.tscn")
onready var target_scene = preload("res://2D Assets/Target.tscn")

var test_id = 0
var player
var platform
var target
var player_direction
var short_platform
var platform_rotation
var player_rotation
var distance = 200
var speed = 500
var platform_position = Vector2(500, 300)
var should_collide
var collided = false
var paused = false
var test_complete = false
var all_complete = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if all_complete:
			restart()
		else:
			pause(!paused)
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _ready():
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".print_failure = print_failure
	restart()

func restart():
	all_complete = false
	test_id = 0
	short_platform = false
	player_direction = 0
	platform_rotation = 0
	player_rotation = 0
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".restart()
	$Timer.start()
	prepare_next_test()

func update_test_result(success, collision):
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".test_result(success, collision)

func update_test_data():
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".test_id = test_id
		$"Around the Clock Test Data".player_class = player.get_class()
		$"Around the Clock Test Data".player_direction = player_direction
		$"Around the Clock Test Data".short_platform = short_platform
		$"Around the Clock Test Data".platform_rotation = platform_rotation
		$"Around the Clock Test Data".player_rotation = player_rotation
		$"Around the Clock Test Data".update_labels()

func set_should_collide():
	# Should never collide unless ...
	should_collide = false
	var angle = (platform_rotation - player_direction + 360) % 360
	if angle > 180:
		should_collide = true

func start_test():
	set_should_collide()
	if test_id % 2:
		player = rigid_player_scene.instance()
	else:
		player = kinematic_player_scene.instance()
	var direction = Vector2(1, 0).rotated(deg2rad(player_direction))
	player.connect("body_entered", self, "_on_body_collided")
	player.gravity_scale = 0
	player.position = platform_position - (direction * distance)
	player.rotate(deg2rad(player_rotation))
	player.linear_velocity = direction * speed
	platform = short_platform_scene.instance() if short_platform else long_platform_scene.instance()
	platform.position = platform_position
	platform.rotate(deg2rad(platform_rotation))
	target = target_scene.instance()
	target.player = player
	if should_collide:
		target.colour = Color(191, 0, 0)
	target.connect("target_reached", self, "_on_target_collided")
	target.position = player.position + (direction * distance * 2)
	add_child(platform)
	add_child(target)
	add_child(player)
	update_test_data()

func prepare_next_test():
	var players = 2
	if test_id > 0 and test_id % players == 0:
		if short_platform:
			if player_direction + direction_step >= 360:
				if platform_rotation + platform_rotation_step >= 360:
					if player_rotation + player_rotation_step >= 360:
						tests_complete()
						return
					else:
						short_platform = false
						player_direction = 0
						platform_rotation = 0
						player_rotation += player_rotation_step
				else:
					short_platform = false
					player_direction = 0
					platform_rotation += platform_rotation_step
			else:
				short_platform = false
				player_direction += direction_step
		else:
			short_platform = true
	test_id += 1
	start_test()

func tests_complete():
	all_complete = true
	$Timer.stop()
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".tests_complete()

func pause(on):
	paused = on
	$Timer.paused = on
	if $"Around the Clock Test Data":
		$"Around the Clock Test Data".pause(on)
	player.linear_velocity = Vector2()
	if player is RigidBody2D:
		player.angular_velocity = 0
	if on:
		if not test_complete:
			test_id -= 1

func end_test():
	player.free()
	platform.free()
	target.free()
	collided = false
	test_complete = false

func _on_body_collided(body):
	collided = true
	test_complete = true
	update_test_result(should_collide, true)
	if not should_collide and stop_on_failure:
		pause(true)

func _on_target_collided():
	test_complete = true
	if not collided:
		update_test_result(!should_collide, false)
		if should_collide and stop_on_failure:
			pause(true)

func _on_Timer_timeout():
	end_test()
	prepare_next_test()
