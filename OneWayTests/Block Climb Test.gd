extends Node2D

var passed = 0
var tests = 2

func _input(event):
	if event.is_action_pressed("ui_accept") and $Complete.visible:
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://Menu.tscn")

func _on_Timer_timeout():
	if passed < tests:
		$"Test Outcome".text = "FAILED!"
	$Complete.visible = true

func _on_goal_reached():
	passed += 1
	if passed >= tests:
		$"Test Outcome".text = "Passed!"

func _on_trap_reached():
	passed -= 1
	$"Test Outcome".text = "FAILED!"
