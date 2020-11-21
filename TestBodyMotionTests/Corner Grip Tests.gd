extends Node2D

export (bool) var stop_on_failure
export (bool) var print_failure = false
export (bool) var loop = false
export (float) var offset_size = 1

onready var rigid_player_scene = preload("res://2D Assets/RigidBody Player.tscn")
onready var kinematic_player_scene = preload("res://2D Assets/KinematicBody Player.tscn")
onready var target_scene = preload("res://2D Assets/Target.tscn")

enum OFFSET { NONE, TOP, SIDE }
enum DIRECTION { UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT }

var test_id = 0
var player
var target
var player_size = Vector2(32, 32)
var distance = 100
var speed = 500
var corner_code
var corner_position
var direction_code
var direction
var offset_code
var offset
var should_collide
var paused = false
var test_complete = false
var all_complete = false

onready var platform_position = $Platform.position
onready var platform_width = $Platform/CollisionShape2D.shape.extents.x
onready var platform_height = $Platform/CollisionShape2D.shape.extents.y
onready var one_way_platform = $Platform/CollisionShape2D.one_way_collision

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if all_complete:
			restart()
		else:
			pause(!paused)
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _ready():
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".print_failure = print_failure
	restart()

func restart():
	all_complete = false
	test_id = 0
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".restart()
	$Timer.start()
	prepare_next_test()

func update_test_result(success, collision):
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".test_result(success, collision)

func update_test_data():
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".test_id = test_id
		$"Corner Grip Test Data".player_class = player.get_class()
		$"Corner Grip Test Data".corner_code = corner_code
		$"Corner Grip Test Data".direction_code = direction_code
		$"Corner Grip Test Data".offset_code = offset_code
		match corner_code:
			CORNER_TOP_LEFT:
				$"Corner Grip Test Data".offset = offset - Vector2(-player_size.x, -player_size.y)
			CORNER_TOP_RIGHT:
				$"Corner Grip Test Data".offset = offset - Vector2(player_size.x, -player_size.y)
		$"Corner Grip Test Data".update_labels()

func set_corner_position():
	corner_position = platform_position
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
					offset += Vector2(offset_size, 0)
				CORNER_TOP_RIGHT:
					offset += Vector2(-offset_size, 0)
		OFFSET.SIDE:
			offset += Vector2(0, offset_size)

func set_should_collide():
	if one_way_platform:
		# Should never collide unless...
		should_collide = false
		# ... direction is downward and...
		if direction.y > 0:
			match offset_code:
				# ... it's aimed at the top or ...
				OFFSET.TOP:
					should_collide = true
				# ...it's aimed at the side but will hit the top first ... or
				OFFSET.SIDE:
					match corner_code:
						CORNER_TOP_LEFT:
							if direction.x < 0:
								should_collide = true
						CORNER_TOP_RIGHT:
							if direction.x > 0:
								should_collide = true
				# ...it's aimed diagonally at the corner (debatable)
				OFFSET.NONE:
					match corner_code:
						CORNER_TOP_LEFT:
							if direction.x > 0:
								should_collide = true
						CORNER_TOP_RIGHT:
							if direction.x < 0:
								should_collide = true
	else: # Normal platform
		# Should always collide unless ...
		should_collide = true
		# ... zero pixel overlap
		match direction_code:
			DIRECTION.LEFT, DIRECTION.RIGHT:
				if offset_code != OFFSET.SIDE:
					should_collide = false
			DIRECTION.DOWN:
				if offset_code != OFFSET.TOP:
					should_collide = false
		# ... it skims the corner (debatable)
		if offset_code == OFFSET.NONE:
			match corner_code:
				CORNER_TOP_LEFT:
					match direction_code:
						DIRECTION.UP_RIGHT, DIRECTION.DOWN_LEFT:
							should_collide = false
				CORNER_TOP_RIGHT:
					match direction_code:
						DIRECTION.DOWN_RIGHT, DIRECTION.UP_LEFT:
							should_collide = false

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
	update_test_data()

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
	all_complete = true
	$Timer.stop()
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".tests_complete()

func pause(on):
	paused = on
	$Timer.paused = on
	if $"Corner Grip Test Data":
		$"Corner Grip Test Data".pause(on)
	player.linear_velocity = Vector2()
	if player is RigidBody2D:
		player.angular_velocity = 0
	if on:
		if not test_complete:
			test_id -= 1

func end_test():
	player.free()
	target.free()
	test_complete = false

func _on_body_collided(body):
	if not test_complete:
		test_complete = true
		update_test_result(should_collide, true)
		if not should_collide and stop_on_failure:
			pause(true)

func _on_target_collided():
	if not test_complete:
		test_complete = true
		update_test_result(!should_collide, false)
		if should_collide and stop_on_failure:
			pause(true)

func _on_Timer_timeout():
	end_test()
	prepare_next_test()

