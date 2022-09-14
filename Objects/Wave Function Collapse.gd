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

var gridSize = Vector2(60,28)

var allInputs
var edgeTiles = []
var nonLegibleTiles = []

class edgeTile:
	var position
	var matches
	
	func setValues(_position, _matches = null):
		position = _position
		matches = _matches

func sortToLowestEntropy(a, b):
	return a.matches.size() < b.matches.size()

func generateMap():#_gridSize):
#	gridSize = _gridSize
	
	allInputs = getAllInputs()
	
	placeCornerPatterns()
	
	update()
	$CanvasLayer/EdgeTilesDraw.show()
	yield(get_tree().create_timer(0.01), "timeout")
	
	while !edgeTiles.empty():
		$CanvasLayer/EdgeTilesDraw.resetEdgeTilesDraw()
		
#		var _tile = edgeTiles[randi() % edgeTiles.size()]
#		var _tile = edgeTiles.front()
		var _tile = getRandomLowestEntropyEdgeTile()
		if _tile == null:
			break
		var _partialPattern = getPartialPatternForTile(_tile.position)
#		var _matches = findAllPartialPatternMatches(_partialPattern)
		if !isTileLegible(_tile, _partialPattern):
			edgeTiles.erase(_tile)
			nonLegibleTiles.append(_tile.position)
		
		getMatchesForEdgeTiles()
		
		edgeTiles.sort_custom(self, "sortToLowestEntropy")
		
		$CanvasLayer/EdgeTilesDraw.addAllEdgeTiles(edgeTiles)
		
		yield(get_tree().create_timer(0.01), "timeout")
	
	print("system config")

func isTileLegible(_tile, _partialPattern):
	_tile.matches.shuffle()
	for _match in _tile.matches:
#		var _randomMatch = _matches[randi() % _matches.size()]
		var _legibleInputs = doesTileHaveLegibleInputs(_tile, _match)
		if typeof(_legibleInputs) != TYPE_BOOL:
			for _legibleTile in _legibleInputs.grid:
				set_cellv(Vector2(_legibleTile.x, _legibleTile.y), _legibleInputs.grid[_legibleTile])
			edgeTiles = _legibleInputs.edgeTiles.duplicate(true)
#			for _edgeTile in _legibleInputs.edgeTiles.keys():
#				edgeTiles[_edgeTile] = _legibleInputs.edgeTiles[_edgeTile]
			
#			for _edgeTile in edgeTiles:
#				var _tileCount = doesEdgeTileHaveSixAdjacentTiles(_edgeTile)
#				if _tileCount <= 5 or _tileCount == 9:
#					edgeTiles.erase(_edgeTile)
			
			return true
	
	return false
#				_grid = updateGrid(_tile, _randomMatch, _grid)
#				drawPatternWithGrid(grid)
#				drawPattern(_tile, _randomMatch)
#				updateEdgeTilesForTile(_tile)



####################################
### Edge tile updating functions ###
####################################

func doesTileHaveLegibleInputs(_tile, _randomMatch):
	### Tiles to be changed
	var _testGrid = addToTestGrid(_tile.position, _randomMatch, {})
	
	### Tiles to be checked for edgetiles
	var _testGridTiles = addToTestGridTiles(_tile.position, [])
	
	### Edgetiles to be looped through
	var _testEdgeTiles = getEdgeTilesForTile(_tile.position, edgeTiles, _testGrid)
	
	### Edgetile to be changed
#	var _newEdgeTiles = _testEdgeTiles.duplicate(true)
	
	### For tiles that have no match
#	var _noMatchForTiles = []
	
	### Legible edgetiles loop
	while !_testEdgeTiles.empty():
		var _testEdgeTile = _testEdgeTiles.front()
		var _partialPattern = getPartialPatternForTile(_testEdgeTile.position, _testGrid)
		var _matches = findAllPartialPatternMatches(_partialPattern)
		if typeof(_matches) == TYPE_BOOL:
			_testEdgeTiles.erase(_testEdgeTile)
#			return false
		else:
			if _matches.size() == 1:# and !_noMatchForTiles.has(_matches[0]):
#				_noMatchForTiles.append(_matches[0])
				_testGrid = addToTestGrid(_testEdgeTile.position, _matches[0], _testGrid)
				_testGridTiles = addToTestGridTiles(_testEdgeTile.position, _testGridTiles)
				_testEdgeTiles = getEdgeTilesForTile(_testEdgeTile.position, _testEdgeTiles, _testGrid)
#				if get_cellv(_testEdgeTile) == INVALID_CELL:
#					_testGrid[_testEdgeTile] = _testEdgeTiles[_testEdgeTile]
#				_testGrid = updateGrid(_testEdgeTile, _matches[0], _testGrid)
#				_newEdgeTiles = getEdgeTilesForTile(_testEdgeTile, _newEdgeTiles, _testGrid)
#				for _edgeTile in _testEdgeTiles.keys():
#					if !_newEdgeTiles.has(_edgeTile):
#						_newEdgeTiles[_edgeTile] = _testEdgeTiles[_edgeTile]
#				_testEdgeTiles = updateEdgeTilesForTileInGrid(_tile, _testGrid, _testEdgeTiles)
			else:
#				if !_newEdgeTiles.has(_testEdgeTile):
#					_newEdgeTiles[_testEdgeTile] = _testEdgeTiles[_testEdgeTile]
				_testEdgeTiles.erase(_testEdgeTile)
	
	### Check what the new edgetiles will be
	var _newTestEdgeTiles = getNewEdgeTiles(_testGrid, _testGridTiles)
	
	return {
		"grid": _testGrid,
		"edgeTiles": _newTestEdgeTiles
	}

func getEdgeTilesForTile(_tile, _edgeTiles, _grid = null):
	var _newEdgeTiles = _edgeTiles.duplicate(true)
	for x in range(_tile.x - 1,  _tile.x + 2):
		for y in range(_tile.y - 1,  _tile.y + 2):
			var _newEdgeTilesTileIndex = checkIfArrayOfClassesHasValue(_newEdgeTiles, "position", Vector2(x,y))
			if x < 2 or y < 2 or x > gridSize.x - 3 or y > gridSize.y - 3:
				continue
			elif _tile == Vector2(x,y) and _newEdgeTilesTileIndex != -1:
				_newEdgeTiles.remove(_newEdgeTilesTileIndex)
			else:
				var _tileCount = getEdgetileTileCount(Vector2(x,y), _grid)
				if (_tileCount >= 3 and _tileCount != 9 and !nonLegibleTiles.has(Vector2(x,y)) and _newEdgeTilesTileIndex == -1):
					var _newEdgeTile = edgeTile.new()
					_newEdgeTile.setValues(Vector2(x,y))
					_newEdgeTiles.append(_newEdgeTile)
				elif _newEdgeTilesTileIndex != -1 and (_tileCount < 3 or _tileCount == 9):
					_newEdgeTiles.remove(_newEdgeTilesTileIndex)
	return _newEdgeTiles

func getEdgetileTileCount(_tile, _grid = null):
	var _partialPattern = getPartialPatternForTile(_tile)
	var _adjacentTiles = PoolVector2Array([
		Vector2(0, 0),
		Vector2(0,-1),
		Vector2(1,-1),
		Vector2(1,0),
		Vector2(1,1),
		Vector2(0,1),
		Vector2(-1,1),
		Vector2(-1,0),
		Vector2(-1,-1)
	])
	var _tileCount = 0
	for _adjacentTile in _adjacentTiles:
		if (_grid != null and _grid.has(Vector2(_tile.x + _adjacentTile.x, _tile.y + _adjacentTile.y)) and _grid[Vector2(_tile.x + _adjacentTile.x, _tile.y + _adjacentTile.y)] != -1) or _partialPattern[1 + _adjacentTile.x][1 + _adjacentTile.y] != -1:
			_tileCount += 1
	return _tileCount

func getNewEdgeTiles(_testGrid, _testGridTiles):
	### New edgetiles
	var _newTestEdgeTiles = []
	
	### Existing edgetiles
	var _newEdgeTiles = edgeTiles.duplicate(true)
	for _edgeTile in _newEdgeTiles:
		var _tileCount = getEdgetileTileCount(_edgeTile.position, _testGrid)
		var _edgetilesTileIndex = checkIfArrayOfClassesHasValue(_newTestEdgeTiles, "position", _edgeTile.position)
		if checkIfPositionHasTile(_edgeTile.position, _testGrid) and _tileCount >= 3 and _tileCount != 9 and !nonLegibleTiles.has(_edgeTile.position) and _edgetilesTileIndex == -1 and !(_edgeTile.position.x < 2 or _edgeTile.position.y < 2 or _edgeTile.position.x > gridSize.x - 3 or _edgeTile.position.y > gridSize.y - 3):
			var _newEdgeTile = edgeTile.new()
			_newEdgeTile.setValues(_edgeTile.position)
			_newTestEdgeTiles.append(_newEdgeTile)
		elif _edgetilesTileIndex != -1:
			_newTestEdgeTiles.remove(_edgetilesTileIndex)
	
	### New edgetiles
	for _edgeTile in _testGridTiles:
		var _tileCount = getEdgetileTileCount(_edgeTile, _testGrid)
		var _edgetilesTileIndex = checkIfArrayOfClassesHasValue(_newTestEdgeTiles, "position", _edgeTile)
		if checkIfPositionHasTile(_edgeTile, _testGrid) and _tileCount >= 3 and _tileCount != 9 and !nonLegibleTiles.has(_edgeTile) and _edgetilesTileIndex == -1 and !(_edgeTile.x < 2 or _edgeTile.y < 2 or _edgeTile.x > gridSize.x - 3 or _edgeTile.y > gridSize.y - 3):
			var _newEdgeTile = edgeTile.new()
			_newEdgeTile.setValues(_edgeTile)
			_newTestEdgeTiles.append(_newEdgeTile)
		elif _edgetilesTileIndex != -1:
			_newTestEdgeTiles.remove(_edgetilesTileIndex)
	
	return _newTestEdgeTiles

func addToTestGrid(_tile, _pattern, _grid):
	var _testGrid = _grid.duplicate(true)
	for x in range(3):
		for y in range(3):
			if !_testGrid.has(Vector2(_tile.x + (x - 1), _tile.y + (y - 1))):
				_testGrid[Vector2(_tile.x + (x - 1), _tile.y + (y - 1))] = _pattern[x][y]
	return _testGrid

func addToTestGridTiles(_tile, _gridTiles):
	var _testGridTiles = _gridTiles.duplicate(true)
	for x in range(5):
		for y in range(5):
			if !_testGridTiles.has(Vector2(_tile.x + (x - 2), _tile.y + (y - 2))):
				_testGridTiles.append(Vector2(_tile.x + (x - 2), _tile.y + (y - 2)))
	return _testGridTiles

func getMatchesForEdgeTiles():
	var _newEdgeTiles = []
	for _edgeTile in edgeTiles:
		if _edgeTile.matches == null:
			var _matches = findAllPartialPatternMatches(getPartialPatternForTile(_edgeTile.position))
			if typeof(_matches) == TYPE_BOOL and _matches == false:
				nonLegibleTiles.append(_edgeTile.position)
			else:
				_edgeTile.matches = _matches
				_newEdgeTiles.append(_edgeTile)
	edgeTiles = _newEdgeTiles

#func updateEdgeTilesForTileInGrid(_tile, _testGrid, _testEdgeTiles):
#	var _grid = _testGrid
#	var _edgeTiles = _testEdgeTiles
#	for x in range(_tile.x - 2,  _tile.x + 3):
#		for y in range(_tile.y - 2,  _tile.y + 3):
#			if x < 2 or y < 2 or x > gridSize.x - 3 or y > gridSize.y - 3:
#				continue
#			elif (
#				x < _tile.x - 1 or
#				x > _tile.x + 1 or
#				y < _tile.y - 1 or
#				y > _tile.y + 1
#			):
#				if _grid[x][y] == -1:
#					if !isEdgeTileInCornerInGrid(_tile, _grid):
#						_edgeTiles.append(Vector2(x,y))
#					elif _edgeTiles.has(Vector2(x,y)):
#						_edgeTiles.erase(Vector2(x,y))
#			elif _edgeTiles.has(Vector2(x,y)):
#				_edgeTiles.erase(Vector2(x,y))
#	return _edgeTiles

#func findAllLegibleTilesAroundTile(_tile):
#	var _legibleTiles = []
#	var _directions = PoolVector2Array([
#		Vector2(0,-1),
#		Vector2(1,-1),
#		Vector2(1,0),
#		Vector2(1,1),
#		Vector2(0,1),
#		Vector2(-1,1),
#		Vector2(-1,0),
#		Vector2(-1,-1)
#	])
#	for _direction in _directions:
#		if edgeTiles.has(_tile + _direction):
#			_legibleTiles.append(_tile + _direction)
#	return _legibleTiles



###############################
### Pattern match functions ###
###############################

func getPartialPatternForTile(_tile, _grid = null):
	var _partialPattern = makeNewPattern()
	for x in range(3):
		for y in range(3):
			if _grid != null and _grid.has(Vector2(x,y)):
				_partialPattern[x][y] = _grid[Vector2(x,y)]
			else:
				_partialPattern[x][y] = get_cellv(Vector2(_tile.x + (x - 1), _tile.y + (y - 1)))
	return _partialPattern

func findAllPartialPatternMatches(_partialPattern):
	var _matches = []
	for _input in allInputs:
		for _inputPattern in _input:
			var _match = isPartialPatternAMatch(_partialPattern, _inputPattern)
			if _match and !_matches.has(_match):
				_matches.append(_inputPattern)
	if _matches.empty():
		return false
	return _matches

func isPartialPatternAMatch(_partialPattern, _inputPattern):
	for x in range(3):
		for y in range(3):
			if _partialPattern[x][y] != -1 and _partialPattern[x][y] != _inputPattern[x][y]:
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
	for tile in _grid.keys():
		set_cellv(Vector2(tile.x, tile.y), _grid[tile])



##########################################
### Input pattern processing functions ###
##########################################

func getAllInputs():
	var _allInputs = []
	for _inputNode in $"../Inputs".get_children():
		var _newInput = []
		for x in range(1, _inputNode.gridSize.x - 1):
			for y in range(1, _inputNode.gridSize.y - 1):
				_newInput.append(getInputPatterns(_inputNode, x, y))
		_allInputs.append(_newInput)
	return _allInputs

func getInputPatterns(_inputNode, x, y):
	var _inputPattern = makeNewPattern()
	var _inputPatternX = 0
	var _inputPatternY = 0
	for patternX in range(x - 1, x + 2):
		for patternY in range(y - 1, y + 2):
			_inputPattern[_inputPatternX][_inputPatternY] = _inputNode.get_cellv(Vector2(patternX, patternY))
			_inputPatternY += 1
		_inputPatternX += 1
		_inputPatternY = 0
	return _inputPattern



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

func getRandomLowestEntropyEdgeTile():
	var _lowestEntropyEdgeTiles = []
	var _lowestEntropyEdgeTileSize = edgeTiles.front().matches.size()
	for _edgeTile in edgeTiles:
		if _edgeTile.matches.size() == _lowestEntropyEdgeTileSize and checkIfArrayOfClassesHasValue(_lowestEntropyEdgeTiles, "position", _edgeTile.position) == -1:
			_lowestEntropyEdgeTiles.append(_edgeTile)
		else:
			break
	return _lowestEntropyEdgeTiles[randi() % _lowestEntropyEdgeTiles.size()]

func placeCornerPatterns():
	var _corners = PoolVector2Array([
		Vector2(2, 2)
#		Vector2(2, gridSize.y - 3),
#		Vector2(gridSize.x - 3, gridSize.y - 3),
#		Vector2(gridSize.x - 3, 2)
	])
	for _corner in _corners:
		drawPattern(_corner, getRandomPattern())
	
	var _partialPattern1 = getPartialPatternForTile(Vector2(3,2))
	var _partialPattern2 = getPartialPatternForTile(Vector2(2,3))
	var _matches1 = findAllPartialPatternMatches(_partialPattern1)
	var _matches2 = findAllPartialPatternMatches(_partialPattern2)
	var _initEdgeTile1 = edgeTile.new()
	_initEdgeTile1.setValues(Vector2(3,2), _matches1)
	var _initEdgeTile2 = edgeTile.new()
	_initEdgeTile2.setValues(Vector2(2,3), _matches2)
	edgeTiles.append(_initEdgeTile1)
	edgeTiles.append(_initEdgeTile2)
	edgeTiles.shuffle()

func checkIfArrayOfClassesHasValue(_array, _property, _value):
	for _index in _array.size():
		if _array[_index][_property] == _value:
			return _index
	return -1

func checkIfPositionHasTile(_position, _testGrid):
	if get_cellv(_position) != -1 or (_testGrid.has(_position) and _testGrid[_position] != -1):
		return true
	return false

