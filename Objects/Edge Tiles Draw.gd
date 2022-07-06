extends Control

func _ready():
	$"../".set_layer(1)
	modulate.a = 0.5

func _draw():
#	draw_rect(Rect2(Vector2(0,0), Vector2(1920, 1080)), Color(180,180,180,10))
	for _tile in $"../../".edgeTiles:
		draw_rect(Rect2($"../../".map_to_world(Vector2(_tile.x, _tile.y), true), Vector2($"../../".cell_size.x, $"../../".cell_size.y)), Color(256,0,0,128))
