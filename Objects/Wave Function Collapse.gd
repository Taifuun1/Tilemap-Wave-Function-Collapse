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
#var gridSize = Vector2(200,200)

var allInputs
var edgeTiles = [
	Vector2(4, 2),
	Vector2(4, 3),
#	Vector2(4, 4),
	Vector2(3, 4),
	Vector2(2, 4)
	
#	Vector2(4, gridSize.y - 3),
#	Vector2(4, gridSize.y - 4),
#	Vector2(4, gridSize.y - 5),
#	Vector2(3, gridSize.y - 5),
#	Vector2(2, gridSize.y - 5),
#
#	Vector2(gridSize.x - 5, gridSize.y - 3),
#	Vector2(gridSize.x - 5, gridSize.y - 4),
#	Vector2(gridSize.x - 5, gridSize.y - 5),
#	Vector2(gridSize.x - 4, gridSize.y - 5),
#	Vector2(gridSize.x - 3, gridSize.y - 5),
#
#	Vector2(gridSize.x - 5, 2),
#	Vector2(gridSize.x - 5, 3),
#	Vector2(gridSize.x - 5, 4),
#	Vector2(gridSize.x - 4, 4),
#	Vector2(gridSize.x - 3, 4)
]

func generateMap():#_gridSize):
#	gridSize = _gridSize
	
	allInputs = getAllInputs()
	
	placeCornerPatterns()
	
	update()
	$CanvasLayer/EdgeTilesDraw.show()
	yield(get_tree().create_timer(0.2), "timeout")
	
	while !edgeTiles.empty():
#		var _tile = edgeTiles[randi() % edgeTiles.size()]
		var _tile = edgeTiles.front()
		
		var _partialPattern = getPartialPatternForTile(_tile)
		var _matches = findAllPartialPatternMatches(_partialPattern)
		if typeof(_matches) == TYPE_ARRAY:
			var _randomMatch = _matches[randi() % _matches.size()]
			var _grid = isTileLegible(_tile)
			if typeof(_grid) == TYPE_ARRAY:
				_grid = updateGrid(_tile, _randomMatch, _grid)
				drawPatternWithGrid(_grid)
#				drawPattern(_tile, _randomMatch)
				updateEdgeTilesForTile(_tile)
			else:
				edgeTiles.erase(_tile)
		else:
			edgeTiles.erase(_tile)
		
#		var _legibleTiles = findAllLegibleTilesAroundTile(_tile)
#		print(_tile)
#		print(_legibleTiles)
#		if typeof(_legibleTiles) == TYPE_ARRAY:
#			pass
		
		
#		update()
		$CanvasLayer/EdgeTilesDraw.update()
		
		yield(get_tree().create_timer(0.01), "timeout")
	
	print("system config")



##########################################
### Input pattern processing functions ###
##########################################

func getAllInputs():
	var _allInputs = []
	for _inputNode in $"../Inputs".get_children():
		var _newInput = []
		for x in range(1, _inputNode.gridSize.x - 1):
			for y in range(1, _inputNode.gridSize.y - 1):
				_newInput.append(getInputPatterns(makeNewPattern(), _inputNode, x, y))
		_allInputs.append(_newInput)
	return _allInputs

func getInputPatterns(_newInputPattern, _inputNode, x, y):
	var _inputPattern = _newInputPattern
	var _inputPatternX = 0
	var _inputPatternY = 0
	for patternX in range(x - 1, x + 2):
		for patternY in range(y - 1, y + 2):
			_inputPattern[_inputPatternX][_inputPatternY] = _inputNode.get_cellv(Vector2(patternX, patternY))
			_inputPatternY += 1
		_inputPatternX += 1
		_inputPatternY = 0
	return _inputPattern



####################################
### Edge tile updating functions ###
####################################

func updateEdgeTiles():
	for _edgeTile in edgeTiles:
		updateEdgeTilesForTile(_edgeTile)

func updateEdgeTilesForTile(_tile):
	for x in range(_tile.x - 2,  _tile.x + 3):
		for y in range(_tile.y - 2,  _tile.y + 3):
			if x < 2 or y < 2 or x > gridSize.x - 3 or y > gridSize.y - 3:
				continue
			elif (
				x < _tile.x - 1 or
				x > _tile.x + 1 or
				y < _tile.y - 1 or
				y > _tile.y + 1
			):
				if get_cellv(Vector2(x,y)) == -1 and !edgeTiles.has(Vector2(x,y)):
					edgeTiles.append(Vector2(x,y))
			elif edgeTiles.has(Vector2(x,y)):
				edgeTiles.erase(Vector2(x,y))

func isTileLegible(_tile):
	var _testGrid = []
	for x in range(gridSize.x):
		_testGrid.append([])
		for y in range(gridSize.y):
			_testGrid[x].append(get_cell(x, y))
	
	var _testEdgeTiles = getEdgeTilesForTile(_tile, [])
	
	var _noMatchForTiles = []
	
	while !_testEdgeTiles.empty():
		var _testEdgeTile = _testEdgeTiles.back()
		var _partialPattern = getPartialPatternForTile(_testEdgeTile)
		var _matches = findAllPartialPatternMatches(_partialPattern)
		if typeof(_matches) == TYPE_BOOL:
			return false
		elif _matches.size() == 1 and !_noMatchForTiles.has(_matches[0]):
			_noMatchForTiles.append(_matches[0])
			_testGrid = updateGrid(_testEdgeTile, _matches[0], _testGrid)
			_testEdgeTiles = updateEdgeTilesForTileInGrid(_tile, _testGrid, _testEdgeTiles)
		else:
			_testEdgeTiles.erase(_testEdgeTile)
	
	return _testGrid

func updateGrid(_tile, _pattern, _testGrid):
	var _grid = _testGrid
	for x in range(3):
		for y in range(3):
			_grid[_tile.x + (x - 1)][_tile.y + (y - 1)] = _pattern[x][y]
	return _grid

func updateEdgeTilesForTileInGrid(_tile, _testGrid, _testEdgeTiles):
	var _grid = _testGrid
	var _edgeTiles = _testEdgeTiles
	for x in range(_tile.x - 2,  _tile.x + 3):
		for y in range(_tile.y - 2,  _tile.y + 3):
			if x < 2 or y < 2 or x > gridSize.x - 3 or y > gridSize.y - 3:
				continue
			elif (
				x < _tile.x - 1 or
				x > _tile.x + 1 or
				y < _tile.y - 1 or
				y > _tile.y + 1
			):
				if _grid[x][y] == -1:
					if !isEdgeTileInCornerInGrid(_tile, _grid):
						_edgeTiles.append(Vector2(x,y))
					elif _edgeTiles.has(Vector2(x,y)):
						_edgeTiles.erase(Vector2(x,y))
			elif _edgeTiles.has(Vector2(x,y)):
				_edgeTiles.erase(Vector2(x,y))
	return _edgeTiles

func getEdgeTilesForTile(_tile, _testEdgeTiles):
	var _edgeTiles = _testEdgeTiles
	for x in range(_tile.x - 2,  _tile.x + 3):
		for y in range(_tile.y - 2,  _tile.y + 3):
			if x < 2 or y < 2 or x > gridSize.x - 3 or y > gridSize.y - 3:
				continue
			elif (
				x < _tile.x - 1 or
				x > _tile.x + 1 or
				y < _tile.y - 1 or
				y > _tile.y + 1
			):
				if get_cellv(Vector2(x,y)) == -1:
					if !isEdgeTileInCorner(_tile):
						_edgeTiles.append(Vector2(x,y))
					elif _edgeTiles.has(Vector2(x,y)):
						_edgeTiles.erase(Vector2(x,y))
			elif _edgeTiles.has(Vector2(x,y)):
				_edgeTiles.erase(Vector2(x,y))
	return _edgeTiles

func isEdgeTileInCorner(_tile):
	var _partialPattern = getPartialPatternForTile(_tile)
	var _isCorner = 0
	for x in range(3):
		for y in range(3):
			if _partialPattern[x][y] == -1:
				_isCorner += 1
	if _isCorner >= 8:
		return true
	return false

func isEdgeTileInCornerInGrid(_tile, _grid):
	var _tileCount = 0
	for x in range(3):
		for y in range(3):
			if _grid[x][y] != -1:
				_tileCount += 1
				if _tileCount > 1:
					return true
	return false

func findAllLegibleTilesAroundTile(_tile):
	var _legibleTiles = []
	var _directions = PoolVector2Array([
		Vector2(0,-1),
		Vector2(1,-1),
		Vector2(1,0),
		Vector2(1,1),
		Vector2(0,1),
		Vector2(-1,1),
		Vector2(-1,0),
		Vector2(-1,-1)
	])
	for _direction in _directions:
		if edgeTiles.has(_tile + _direction):
			_legibleTiles.append(_tile + _direction)
	return _legibleTiles



###############################
### Pattern match functions ###
###############################

func getPartialPatternForTile(_tile):
	var _partialPattern = makeNewPattern()
	for x in range(3):
		for y in range(3):
			_partialPattern[x][y] = get_cellv(Vector2(_tile.x + (x - 1), _tile.y + (y - 1)))
	return _partialPattern

func findAllPartialPatternMatches(_partialPattern):
	var _matches = []
	for _input in allInputs:
		for _inputPattern in _input:
			var _match = isPartialPatternAMatch(_partialPattern, _inputPattern)
			if _match:
				_matches.append(_inputPattern)
	if _matches.empty():
		return false
	return _matches

func isPartialPatternAMatch(_partialPattern, _inputPattern):
#	print(_partialPattern)
#	print(_inputPattern)
#	print("")
	for x in range(3):
		for y in range(3):
#			print(_partialPattern[x][y] == -1)
#			print(_partialPattern[x][y] == _inputPattern[x][y])
#			print("")
			if (
				_partialPattern[x][y] == -1 or
				_partialPattern[x][y] == _inputPattern[x][y]
			):
				continue
			return false
	return true



################################
### Tile placement functions ###
###############################

func drawPattern(_tile, _pattern):
	for x in range(3):
		for y in range(3):
			set_cellv(Vector2(_tile.x + (x - 1), _tile.y + (y - 1)), _pattern[x][y])

func drawPatternWithGrid(_grid):
	for x in range(_grid.size()):
		for y in range(_grid[x].size()):
			set_cellv(Vector2(x, y), _grid[x][y])



#########################
### Drawing functions ###
#########################

#func _draw():
#	draw_rect(Rect2(Vector2(0,0), Vector2(1920, 1080)), Color(180,180,180,0.1))
#	for _tile in edgeTiles:
#		draw_rect(Rect2(map_to_world(Vector2(_tile.x, _tile.y), true), Vector2(cell_size.x, cell_size.y)), Color(64,128,0))



########################
### Helper functions ###
########################

func makeNewPattern():
	var _newInputPattern = []
	for x in range(3):
		_newInputPattern.append([])
		for _y in range(3):
			_newInputPattern[x].append(-1)
	return _newInputPattern

func getRandomPattern():
	var _randomInput = randi() % allInputs.size()
	var _randomPattern = allInputs[_randomInput][randi() % allInputs[_randomInput].size()]
	return _randomPattern

func placeCornerPatterns():
	var _corners = PoolVector2Array([
		Vector2(2, 2)
#		Vector2(2, gridSize.y - 3),
#		Vector2(gridSize.x - 3, gridSize.y - 3),
#		Vector2(gridSize.x - 3, 2)
	])
	for _corner in _corners:
		drawPattern(_corner, getRandomPattern())
























