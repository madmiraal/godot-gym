extends Node2D

export (bool) var stop_on_failure
export (bool) var print_failure = false
export (bool) var loop = false

onready var rigid_player_scene = preload("res://2DAssets/RigidBody Player.tscn")
onready var kinematic_player_scene = preload("res://2DAssets/KinematicBody Player.tscn")
onready var target_scene = preload("res://2DAssets/Target.tscn")

enum OFFSET { NONE, TOP, SIDE }
enum DIRECTION { UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT }

var test_id = 0
var player
var target
var player_size = Vector2(32, 32)
var distance = 100
var speed = 500
var corner_code
var corner_name = ""
var corner_position
var direction_code
var direction_name = ""
var direction
var offset_code
var offset_name = ""
var offset
var passed = 0
var failed = 0
var should_collide
var collided = false
var paused = false
var complete = false
onready var platform_postion = $Platform.position
onready var platform_width = $Platform/CollisionShape2D.shape.extents.x
onready var platform_height = $Platform/CollisionShape2D.shape.extents.y

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if complete:
			restart()
		else:
			pause(!paused)
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _ready():
	if print_failure:
		print("Corner Grip Test Results")
		print("========================")
		printt("Test", "Failure", "Body", "Direction", "Offset", "Corner")
	prepare_next_test()

func restart():
	complete = false
	test_id = 0
	passed = 0
	failed = 0
	$Complete.visible = false
	$Timer.start()
	prepare_next_test()

func print_details(collided):
	var failure = "Collided" if collided else "Passed"
	printt(test_id, failure, player.get_class(), direction_name, offset_name, corner_name)

func update_test_labels():
	$"Test".text = "Test " + str(test_id)
	$"Player".text    = "Player: " + player.get_class()
	corner_name = "Corner: "
	match corner_code:
		CORNER_TOP_LEFT:
			corner_name += "Top-Left"
		CORNER_TOP_RIGHT:
			corner_name += "Top-Right"
	$"Corner".text = corner_name
	direction_name = "Direction: "
	match direction_code:
		DIRECTION.UP, DIRECTION.UP_RIGHT, DIRECTION.UP_LEFT:
			direction_name += "Up"
		DIRECTION.DOWN, DIRECTION.DOWN_RIGHT, DIRECTION.DOWN_LEFT:
			direction_name += "Down"
	match direction_code:
		DIRECTION.UP_RIGHT, DIRECTION.UP_LEFT, DIRECTION.DOWN_RIGHT, DIRECTION.DOWN_LEFT:
			direction_name += "-"
	match direction_code:
		DIRECTION.DOWN_LEFT, DIRECTION.LEFT, DIRECTION.UP_LEFT:
			direction_name += "Left"
		DIRECTION.UP_RIGHT, DIRECTION.RIGHT, DIRECTION.DOWN_RIGHT:
			direction_name += "Right"
	$"Direction".text = direction_name
	offset_name = "None: "
	match offset_code:
		OFFSET.SIDE:
			offset_name = "Side: "
		OFFSET.TOP:
			offset_name = "Top: "
	match corner_code:
		CORNER_TOP_LEFT:
			offset_name += str(offset - Vector2(-player_size.x, -player_size.y))
		CORNER_TOP_RIGHT:
			offset_name += str(offset - Vector2(player_size.x, -player_size.y))
	$"Offset".text    = "Offset: " + offset_name
	$"Tests Passed".text = "Tests passed: " + str(passed)
	$"Tests Failed".text = "Tests failed: " + str(failed)
	$"Collided".text = "Collided: ?"
	$"This Test".text = "This Test: ?"

func set_corner_position():
	corner_position = platform_postion
	match corner_code:
		CORNER_TOP_LEFT:
			corner_position.x -= platform_width
			corner_position.y -= platform_height
		CORNER_TOP_RIGHT:
			corner_position.x += platform_width
			corner_position.y -= platform_height

func set_direction():
	direction = Vector2()
	match direction_code:
		DIRECTION.RIGHT, DIRECTION.UP_RIGHT, DIRECTION.DOWN_RIGHT:
			direction.x = 1
		DIRECTION.LEFT, DIRECTION.UP_LEFT, DIRECTION.DOWN_LEFT:
			direction.x = -1
	match direction_code:
		DIRECTION.DOWN, DIRECTION.DOWN_LEFT, DIRECTION.DOWN_RIGHT:
			direction.y = 1
		DIRECTION.UP, DIRECTION.UP_LEFT, DIRECTION.UP_RIGHT:
			direction.y = -1
	direction = direction.normalized()

func set_offset():
	offset = Vector2()
	match corner_code:
		CORNER_TOP_LEFT:
			offset = Vector2(-player_size.x, -player_size.y)
		CORNER_TOP_RIGHT:
			offset = Vector2(player_size.x, -player_size.y)
	match offset_code:
		OFFSET.TOP:
			match corner_code:
				CORNER_TOP_LEFT:
					offset += Vector2(1, 0)
				CORNER_TOP_RIGHT:
					offset += Vector2(-1, 0)
		OFFSET.SIDE:
			offset += Vector2(0, 1)

func set_should_collide():
	# Should never collide unless...
	should_collide = false
	# ... direction is downward and it's not hitting a side
	if direction.y > 0 and offset_code != OFFSET.SIDE:
		should_collide = true
	# ... or it will hit the top first.
	match corner_code:
		CORNER_TOP_LEFT:
			if direction.y > 0 and direction.x < 0:
				should_collide = true
		CORNER_TOP_RIGHT:
			if direction.y > 0 and direction.x > 0:
				should_collide = true

func start_test():
	set_corner_position()
	set_direction()
	set_offset()
	set_should_collide()
	if test_id % 2:
		player = rigid_player_scene.instance()
	else:
		player = kinematic_player_scene.instance()
	player.connect("body_entered", self, "_on_body_collided")
	player.gravity_scale = 0
	player.position = corner_position + offset - direction * distance 
	player.linear_velocity = direction * speed
	target = target_scene.instance()
	target.player = player
	if should_collide:
		target.colour = Color(191, 0, 0)
	target.connect("target_reached", self, "_on_target_collided")
	target.position = player.position + (direction * distance * 4)
	add_child(player)
	add_child(target)
	update_test_labels()

func prepare_next_test():
	var players = 2
	var corners = 2
	var directions = 5
	var offsets = OFFSET.size()
	if test_id == players * corners * directions * offsets:
		if loop:
			test_id %= players * corners * directions * offsets
		else:
			tests_complete()
			return
	var code = test_id / players
	offset_code = code % offsets
	code /= offsets
	direction_code = code % directions
	code /= directions
	corner_code = code % corners
	match corner_code:
		0:
			corner_code = CORNER_TOP_LEFT
			direction_code += 1
		1:
			corner_code = CORNER_TOP_RIGHT
			direction_code += 3
	test_id += 1
	start_test()

func tests_complete():
	complete = true
	$Timer.stop()
	$Complete.visible = true
	if print_failure:
		print("Tests passed: ", passed)
		print("Tests failed: ", failed)

func pause(on):
	paused = on
	$Timer.paused = on
	$Paused.visible = on
	player.linear_velocity = Vector2()
	if player is RigidBody2D:
		player.angular_velocity = 0

func end_test():
	player.free()
	target.free()
	collided = false

func _on_body_collided(body):
	collided = true
	var test_text = "This Test: "
	if should_collide:
		passed += 1
		test_text += "Passed!"
	else:
		failed += 1
		test_text += "FAILED!"
		if print_failure:
			print_details(true)
		if stop_on_failure:
			pause(true)
	update_test_labels()
	$"This Test".text = test_text
	$"Collided".text = "Collided: True"

func _on_target_collided():
	if not collided:
		var test_text = "This Test: "
		if should_collide:
			failed += 1
			test_text += "FAILED!"
			if print_failure:
				print_details(false)
			if stop_on_failure:
				pause(true)
		else:
			passed += 1
			test_text += "Passed!"
		update_test_labels()
		$"This Test".text = test_text
		$"Collided".text = "Collided: False"

func _on_Timer_timeout():
	end_test()
	prepare_next_test()

