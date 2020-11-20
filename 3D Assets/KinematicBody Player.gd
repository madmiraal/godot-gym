extends KinematicBody

signal body_entered

export var linear_velocity = Vector3(0, 0, 0)
export var gravity_scale = 1.2

var collided = false

func _physics_process(delta):
	linear_velocity.y -= gravity_scale * 9.8 * delta
	linear_velocity = move_and_slide(linear_velocity, Vector3.UP)
	if not collided and get_slide_count() > 0:
		collided = true
		emit_signal("body_entered", get_slide_collision(0).collider)
