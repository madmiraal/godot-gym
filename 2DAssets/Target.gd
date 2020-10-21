extends Area2D

signal target_reached

export (Color) var colour = Color.green
export (NodePath) var player_path
var player

func _ready():
	if player == null:
		player = get_node(player_path)

func _on_body_entered(body):
	if body == player:
		$Polygon2D.color = colour
		emit_signal("target_reached")
