extends Node

export var start_separation = 0
export var finish_separation = 32
export var margin = 0.08
export var pause_on_failure = false
export var print_failure = false
export var use_rigidbody = false

var rigid_player_scene
var kinematic_player_scene
var player1
var player2
var player_width
var separation
var motion
var step_size
var starting_position1
var starting_position2
var safe_distance
var passed
var failed
var total_passed
var total_failed
var complete
var paused

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if complete:
			player1.free()
			player2.free()
			restart()
		else:
			pause(!paused)
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _ready():
	var node = self
	if node is Spatial:
		rigid_player_scene = preload("res://3DAssets/RigidBody Player.tscn")
		kinematic_player_scene = preload("res://3DAssets/KinematicBody Player.tscn")
		starting_position2 = Vector3(0, 0, 0)
		motion = Vector3()
		step_size = 0.1
		if finish_separation == 32:
			finish_separation /= 32
		if margin == 0.08:
			margin *= 0.001 / 0.08
	else:
		rigid_player_scene = preload("res://2DAssets/RigidBody Player.tscn")
		kinematic_player_scene = preload("res://2DAssets/KinematicBody Player.tscn")
		starting_position2 = Vector2(500, 300)
		motion = Vector2()
		step_size = 1
	var player = rigid_player_scene.instance()
	player_width = player.get_child(0).get_shape().extents.x * 2
	player.free()
	restart()

func update_labels(result_text):
	if $"Teleportation Test Data":
		$"Teleportation Test Data".margin = margin
		$"Teleportation Test Data".total_passed = total_passed + passed
		$"Teleportation Test Data".total_failed = total_failed + failed
		$"Teleportation Test Data".separation = separation
		$"Teleportation Test Data".passed = passed
		$"Teleportation Test Data".failed = failed
		$"Teleportation Test Data".motion_distance = motion.x
		$"Teleportation Test Data".collision_separation = safe_distance - motion.x
		$"Teleportation Test Data".result = result_text

func pause(on):
	paused = on
	if paused:
		$"Start Timer".stop()
		$"Finish Timer".stop()
	else:
		if pause_on_failure:
			end_test()
		else:
			motion.x -= step_size
			prepare_next_test()

func restart():
	if $"Teleportation Test Data":
		$"Teleportation Test Data".complete = ""
	starting_position1 = starting_position2
	separation = start_separation - step_size
	motion.x = (player_width + separation) * 2 + 1
	total_passed = 0
	total_failed = 0
	passed = 0
	failed = 0
	complete = false
	if print_failure:
		print("Teleportation Test Results")
		print("==========================")
		print("Margin: ", margin)
		print("Player2 position: ", starting_position2.x)
	prepare_next_test()

func prepare_next_test():
	if motion.x >= (player_width + separation) * 2:
		total_passed += passed
		total_failed += failed
		passed = 0
		failed = 0
		separation += step_size
		motion.x = 0
		starting_position1.x = starting_position2.x - player_width - separation
		safe_distance = separation
		if print_failure:
			print("Player1 position: ", starting_position1.x)
			print("Separation: ", starting_position2.x - starting_position1.x)
			print("Safe distance: ", safe_distance)
			printt("X-Motion", "Collision", "Separation", "Distance")
	else:
		motion.x += step_size
	if use_rigidbody:
		player1 = rigid_player_scene.instance()
		player1.mode = RigidBody2D.MODE_STATIC
		player2 = rigid_player_scene.instance()
		player2.mode = RigidBody2D.MODE_STATIC
	else:
		player1 = kinematic_player_scene.instance()
		player1.set_safe_margin(margin)
		player2 = kinematic_player_scene.instance()
		player2.set_safe_margin(margin)
	player1.transform.origin = starting_position1
	player1.gravity_scale = 0
	player1.collision_mask = 7
	player1.find_node("Label").text = "Moving"
	add_child(player1)
	player2.transform.origin = starting_position2
	player2.gravity_scale = 0
	player2.collision_mask = 7
	player2.find_node("Label").text = "Stationary"
	add_child(player2)
	update_labels("")
	$"Start Timer".start()

func perform_test():
	var collided
	if use_rigidbody:
		collided = player1.test_motion(motion, false, margin)
	else:
		collided = player1.test_move(player1.get_global_transform(), motion)
	var failure = false
	var collision_separation = player2.transform.origin.x - player1.transform.origin.x - motion.x
	if collided:
		if $"Teleportation Test Data":
			$"Teleportation Test Data".collided = "Yes"
		if motion.x <= safe_distance:
			failure = true
	else:
		if $"Teleportation Test Data":
			$"Teleportation Test Data".collided = "No"
		player1.translate(motion)
		if motion.x > safe_distance:
			failure = true
	if failure:
		if print_failure:
			printt(motion.x, collided, collision_separation, collision_separation - player_width)
		failed += 1
		update_labels("FAILED!")
		if pause_on_failure:
			pause(true)
		else:
			$"Finish Timer".start(.1)
	else:
		passed += 1
		update_labels("Passed")
		$"Finish Timer".start(.1)

func end_test():
	if motion.x >= (player_width + separation) * 2:
		if print_failure:
			print("Passed: ", passed)
			print("Failed: ", failed)
			print("")
		if separation >= finish_separation:
			if print_failure:
				print("Total passed: ", total_passed + passed)
				print("Total failed: ", total_failed + failed)
			complete = true
			if $"Teleportation Test Data":
				$"Teleportation Test Data".complete = "ALL TESTS COMPLETE!"
			return
	player1.free()
	player2.free()
	prepare_next_test()
