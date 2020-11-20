extends Control

func _on_Test1_pressed():
	get_tree().change_scene("res://OneWayTests/Swimming Pool Tests.tscn")

func _on_Test2_pressed():
	get_tree().change_scene("res://OneWayTests/Block Climb Test.tscn")

func _on_Test3_pressed():
	get_tree().change_scene("res://OneWayTests/One-Way Corner Grip Tests.tscn")

func _on_Test4_pressed():
	get_tree().change_scene("res://TestBodyMotionTests/Corner Grip Tests.tscn")

func _on_Test5_pressed():
	get_tree().change_scene("res://TestBodyMotionTests/Teleportation 2D Tests.tscn")

func _on_Test6_pressed():
	get_tree().change_scene("res://TestBodyMotionTests/Teleportation 3D Tests.tscn")
