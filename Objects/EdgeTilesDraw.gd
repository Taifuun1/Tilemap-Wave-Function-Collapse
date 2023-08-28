extends Control

var _rect = load("res://Objects/Rectangle.tscn")

func addAllEdgeTiles(_edgeTiles):
	for _edgeTile in _edgeTiles:
		addRect(_edgeTile.position)

func addRect(_pos):
	var _newRect = _rect.instantiate()
	_newRect.position = Vector2(_pos.x * 32, _pos.y * 32)
	add_child(_newRect)

func resetEdgeTilesDraw():
	for _child in get_children():
		_child.queue_free()
