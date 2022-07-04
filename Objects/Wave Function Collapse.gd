extends TileMap

enum tiles { 
	EMPTY
	CORRIDOR
	WALL_DUNGEON
	FLOOR_DUNGEON
	SIDEWALK
	DOWN_STAIR_DUNGEON
	UP_STAIR_DUNGEON
	DOOR_CLOSED
	DOOR_OPEN
	GRASS
	SEA
	SAND
	SOIL
	WALL_SAND
	WALL_BRICK_SAND
	FLOOR_SAND
	DOWN_STAIR_SAND
	UP_STAIR_SAND
	WALL_BOARD
}

var gridSize = Vector2(60,24)

var allInputs
var edgeTiles = []

func generateMap():#_gridSize):
#	gridSize = _gridSize
	
	allInputs = getAllInputs()
	
	for x in gridSize.x:
		for y in gridSize.y:
			if (
				(
					x == 0
				) or
				(
					x == gridSize.x - 1
				) or
				(
					y == 0 and
					x != 0 and
					x != gridSize.x - 1
				) or
				(
					y == gridSize.y - 1 and
					x != 0 and
					x != gridSize.x - 1
				)
			):
				edgeTiles.append(Vector2(x, y))
	
	drawEdgeTiles()
	
	while !edgeTiles.empty():
		var _tile = edgeTiles[randi() % edgeTiles.size()]
		
		# M E G A wave function collapse
		
		updateEdgeTilesForTile(_tile)
	
	print("system config")

func getAllInputs():
	var _allInputs = []
	for _inputNode in $"../Inputs".get_children():
		var _newInput = []
		for x in range(1, _inputNode.gridSize.x - 1):
			for y in range(1, _inputNode.gridSize.y - 1):
				_newInput.append(getInputPatterns(makeNewInputPattern(), _inputNode, x, y))
		_allInputs.append(_newInput)
	return _allInputs

func makeNewInputPattern():
	var _newInputPattern = []
	for x in range(3):
		_newInputPattern.append([])
		for _y in range(3):
			_newInputPattern[x].append(-1)
	return _newInputPattern

func getInputPatterns(_newInputPattern, _inputNode, x, y):
	var _inputPatternX = 0
	var _inputPatternY = 0
	for patternX in range(x - 1, x + 2):
		for patternY in range(y - 1, y + 2):
			_newInputPattern[_inputPatternX][_inputPatternY] = _inputNode.get_cellv(Vector2(patternX, patternY))
			_inputPatternY += 1
		_inputPatternX += 1
		_inputPatternY = 0

func updateEdgeTilesForTile(_tile):
	for x in range(_tile.x - 2,  _tile.x + 3):
		for y in range(_tile.y - 2,  _tile.y + 3):
			if x < 0 or y < 0 or x > gridSize.x - 1 or y > gridSize.y - 1:
				continue
			elif (
				x < _tile.x - 1 or
				x > _tile.x + 1 or
				y < _tile.y - 1 or
				y > _tile.y + 1
			):
				if get_cellv(Vector2(x,y)) == tiles.EMPTY and !edgeTiles.has(Vector2(x,y)):
					edgeTiles.append(Vector2(x,y))
				elif edgeTiles.has(Vector2(x,y)):
					edgeTiles.erase(Vector2(x,y))
			elif edgeTiles.has(Vector2(x,y)):
				edgeTiles.erase(Vector2(x,y))

func drawEdgeTiles():
	for _tile in edgeTiles:
		set_cellv(_tile, tiles.WALL_SAND)




