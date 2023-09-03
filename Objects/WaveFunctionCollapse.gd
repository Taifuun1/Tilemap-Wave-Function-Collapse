extends WFCInputCreation
class_name WaveFunctionCollapse

var isEdgeTileCheckDone = true


func _ready():
	set_process(false)

func _process(_delta):
	if !edgeTiles.is_empty() and isEdgeTileCheckDone:
		isEdgeTileCheckDone = false
		var _tile = getRandomLowestEntropyEdgeTile()
		if _tile == null:
			return
		if !isTileLegible(_tile):
			edgeTiles.erase(_tile)
			nonLegibleTiles.append(_tile.position)
		
		getMatchesForEdgeTiles()
		edgeTiles.sort_custom(helperFunctions.sortToLowestEntropy)
		
		$CanvasLayer/EdgeTilesDraw.resetEdgeTilesDraw()
		$CanvasLayer/EdgeTilesDraw.addAllEdgeTiles(edgeTiles)
		isEdgeTileCheckDone = true
	else:
#		trimGenerationEdges()
		fillEmptyGenerationTiles(24)
		set_process(false)

func generateMap() -> void:
	assignAllInputs()
	placeCornerPatterns()
	
	set_process(true)

func isTileLegible(_tile) -> bool:
	_tile.matches.shuffle()
	for _match in _tile.matches:
		var _legibleInputs = doesTileHaveLegibleInputs(_tile, _match)
		if typeof(_legibleInputs) != TYPE_BOOL:
			for _legibleTile in _legibleInputs.tiles:
				generatedTiles[Vector2(_legibleTile.x, _legibleTile.y)] = _legibleInputs.tiles[_legibleTile]
				set_cell(0, _legibleTile.floor(), _legibleInputs.tiles[_legibleTile], Vector2i(0, 0))
			for _edgeTile in _legibleInputs.edgeTiles.add:
				var _edgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(edgeTiles, "position", _edgeTile.position)
				if _edgeTileIndex == -1:
					edgeTiles.append(_edgeTile)
			for _edgeTile in _legibleInputs.edgeTiles.remove:
				var _edgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(edgeTiles, "position", _edgeTile.position)
				if _edgeTileIndex != -1:
					edgeTiles.remove_at(_edgeTileIndex)
			return true
	return false

func getMatchesForEdgeTiles() -> void:
	var _newEdgeTiles = []
	for _edgeTile in edgeTiles:
		if _edgeTile.matches == null:
			var _matches = findAllPartialPatternMatches(getPartialPatternForTile(_edgeTile.position, generatedTiles))
			if typeof(_matches) == TYPE_BOOL and _matches == false:
				nonLegibleTiles.append(_edgeTile.position)
			else:
				_edgeTile.matches = _matches
				_newEdgeTiles.append(_edgeTile)
		else:
			_newEdgeTiles.append(_edgeTile)
	edgeTiles = _newEdgeTiles



#################################
### Tile legibility functions ###
#################################

func doesTileHaveLegibleInputs(_tile, _randomMatch) -> Dictionary:
	### Tiles to be changed
	var _tilesToBeChanged = addToTilesToBeChanged(_tile.position, _randomMatch)
	
	### Tiles to be checked for edgetiles
	var _tilesToBeCheckedForEdgeTiles = addToTilesToBeCheckedForEdgeTiles(_tile.position)
	
	### Edgetiles to be checked for a single match
	var _testSingleMatchEdgeTiles = getEdgeTilesForTile(_tile.position, _tilesToBeChanged, [])

	### Check what edgetiles are legible
	var _i = 0
	while _i < 5:
		var _tiles = checkForEdgeTilesWithASingleMatch(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles, _testSingleMatchEdgeTiles)
		if !_tiles.size():
			break
		else:
			_tilesToBeChanged = _tiles.tilesToBeChanged
			_tilesToBeCheckedForEdgeTiles = _tiles.tilesToBeCheckedForEdgeTiles
			_testSingleMatchEdgeTiles = _tiles.testSingleMatchEdgeTiles
			_i += 1
	
	### Check what the new edgetiles will be
	var _newTestEdgeTiles = getNewEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles)
	
	return {
		"tiles": _tilesToBeChanged,
		"edgeTiles": {
			"add": _newTestEdgeTiles.add,
			"remove": _newTestEdgeTiles.remove
		}
	}

func addToTilesToBeChanged(_tile, _pattern, _currentTestTiles = {}) -> Dictionary:
	var _testTiles = _currentTestTiles.duplicate(true)
	var _i = 0
	for _x in range(-1, 2):
		for _y in range(-1, 2):
			var _checkedTile = Vector2(_tile.x + _x, _tile.y + _y)
			if (
				!_testTiles.has(_checkedTile) and
				!generatedTiles.has(_checkedTile) and
				helperFunctions.isTileInsideGrid(_checkedTile, gridSize)
			):
				_testTiles[_checkedTile] = _pattern[_i]
			_i += 1
	return _testTiles

func addToTilesToBeCheckedForEdgeTiles(_tile, _currentEdgeTiles = {}) -> Dictionary:
	var _newEdgeTiles = _currentEdgeTiles.duplicate(true)
	for x in range(-2, 3):
		for y in range(-2, 3):
			var _checkedTile = Vector2(_tile.x + x, _tile.y + y)
			if !_newEdgeTiles.has(_checkedTile):
				var _edgeTile = edgeTile.edgeTile.new()
				_edgeTile.setValues(_checkedTile)
				_newEdgeTiles[_checkedTile] = _edgeTile
	return _newEdgeTiles

func getEdgeTilesForTile(_tile, _tilesToBeChanged, _currentEdgeTiles) -> Array:
	var _newEdgeTiles = _currentEdgeTiles.duplicate(true)
	for x in range(_tile.x - 1,  _tile.x + 2):
		for y in range(_tile.y - 1,  _tile.y + 2):
			var _newEdgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(_newEdgeTiles, "position", Vector2(x,y))
			if _tile == Vector2(x,y) and _newEdgeTileIndex != -1:
				_newEdgeTiles.remove_at(_newEdgeTileIndex)
			elif (
				!isPatternFull(Vector2(x,y), _tilesToBeChanged) and
				_newEdgeTileIndex == -1 and
				!nonLegibleTiles.has(Vector2(x,y)) and
				!helperFunctions.isTileOutsideGrid(_tile, gridSize)
			):
				var _newEdgeTile = edgeTile.edgeTile.new()
				_newEdgeTile.setValues(Vector2(x,y))
				_newEdgeTiles.append(_newEdgeTile)
			elif _newEdgeTileIndex != -1:
				_newEdgeTiles.remove_at(_newEdgeTileIndex)
	return _newEdgeTiles

func checkForEdgeTilesWithASingleMatch(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles, _testSingleMatchEdgeTiles) -> Dictionary:
	var _newTilesToBeChanged = _tilesToBeChanged.duplicate(true)
	var _newTilesToBeCheckedForEdgeTiles = _tilesToBeCheckedForEdgeTiles.duplicate(true)
	var _newTestSingleMatchEdgeTiles = _testSingleMatchEdgeTiles.duplicate(true)
	var _singleMatchFound = false
	
	for _edgeTile in _testSingleMatchEdgeTiles:
		var _partialPattern = getPartialPatternForTile(_edgeTile.position, generatedTiles, _tilesToBeChanged)
		var _matches = findAllPartialPatternMatches(_partialPattern)
		if _matches.size() == 1:
			_singleMatchFound = true
			_newTilesToBeChanged = addToTilesToBeChanged(_edgeTile.position, _matches[0], _newTilesToBeChanged)
			_newTilesToBeCheckedForEdgeTiles = addToTilesToBeCheckedForEdgeTiles(_edgeTile.position, _newTilesToBeCheckedForEdgeTiles)
			_newTestSingleMatchEdgeTiles = getEdgeTilesForTile(_edgeTile.position, _newTilesToBeChanged, _newTestSingleMatchEdgeTiles)
	
	if _singleMatchFound:
		return {
			"tilesToBeChanged": _newTilesToBeChanged,
			"tilesToBeCheckedForEdgeTiles": _newTilesToBeCheckedForEdgeTiles,
			"testSingleMatchEdgeTiles": _newTestSingleMatchEdgeTiles
		}
	else:
		return {}

func getNewEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles) -> Dictionary:
	var _newAddTestEdgeTiles = []
	var _newRemoveTestEdgeTiles = []
	
	for _edgeTile in _tilesToBeCheckedForEdgeTiles.values():
		var _addEdgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(_newAddTestEdgeTiles, "position", _edgeTile.position)
		var _removeEdgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(_newRemoveTestEdgeTiles, "position", _edgeTile.position)
		if (
			(
				_tilesToBeChanged.has(_edgeTile.position) or
				generatedTiles.has(_edgeTile.position)
			) and
			!nonLegibleTiles.has(_edgeTile.position) and
			_addEdgeTileIndex == -1 and
			!isPatternFull(_edgeTile.position, _tilesToBeChanged) and
			!helperFunctions.isTileOutsideGrid(_edgeTile.position, gridSize)
		):
			var _newEdgeTile = edgeTile.edgeTile.new()
			_newEdgeTile.setValues(_edgeTile.position)
			_newAddTestEdgeTiles.append(_newEdgeTile)
			if _removeEdgeTileIndex != -1:
				_newRemoveTestEdgeTiles.remove_at(_removeEdgeTileIndex)
		elif generatedTiles.has(_edgeTile.position):
			var _newEdgeTile = edgeTile.edgeTile.new()
			_newEdgeTile.setValues(_edgeTile.position)
			_newRemoveTestEdgeTiles.append(_newEdgeTile)
			if _addEdgeTileIndex != -1:
				_newAddTestEdgeTiles.remove_at(_addEdgeTileIndex)
	
	return {
		"add": _newAddTestEdgeTiles,
		"remove": _newRemoveTestEdgeTiles
	}


################################
### Tile placement functions ###
################################

func drawPattern(_tile, _pattern) -> void:
	if typeof(_pattern) == TYPE_BOOL:
		return
	var _index = 0
	for x in range(3):
		for y in range(3):
			var _drawnTile = Vector2(_tile.x + (x - 1), _tile.y + (y - 1))
			set_cell(0, _drawnTile, _pattern[_index], Vector2i(0, 0))
			generatedTiles[_drawnTile] = _pattern[_index]
			_index += 1

func placeCornerPatterns() -> void:
	drawPattern(Vector2(1, 1), getRandomPattern())
	
	var _edgeTiles = []
	var _newEdgeTile1 = edgeTile.edgeTile.new()
	var _newEdgeTile2 = edgeTile.edgeTile.new()
	_newEdgeTile1.setValues(Vector2(1,2))
	_newEdgeTile2.setValues(Vector2(2,1))
	_edgeTiles.append(_newEdgeTile1)
	_edgeTiles.append(_newEdgeTile2)
	
	for _edgeTile in _edgeTiles:
		var _matches = findAllPartialPatternMatches(getPartialPatternForTile(_edgeTile.position, generatedTiles))
		if typeof(_matches) == TYPE_BOOL:
			continue
		_edgeTile.setValues(_edgeTile.position, _matches)
		edgeTiles.append(_edgeTile)

func trimGenerationEdges() -> void:
	var _trimmedGeneratedTiles = {}
	var _generatedTilesCopy = generatedTiles.duplicate(true)
	clear()
	for _tile in _generatedTilesCopy:
		if (
			_tile.x > 4 and
			_tile.y > 4 and
			_tile.x < gridSize.x - 4 and
			_tile.y < gridSize.y - 4
		):
			_trimmedGeneratedTiles[_tile] = _generatedTilesCopy[_tile]
			set_cell(0, _tile, _generatedTilesCopy[_tile], Vector2(0, 0))
	generatedTiles = _trimmedGeneratedTiles

func fillEmptyGenerationTiles(_fillTile, _fillEdges = null) -> void:
	for _x in range(gridSize.x):
		for _y in range(gridSize.y):
			var _tile = Vector2(_x, _y)
			if !generatedTiles.has(_tile):
				generatedTiles[_tile] = _fillTile
				set_cell(0, _tile, _fillTile, Vector2(0, 0))
	if _fillEdges != null:
		for x in range(generatedTiles.size()):
			if generatedTiles[x][0].tile == tiles.DOOR_CLOSED:
				generatedTiles[x][0].tile = tiles[_fillEdges]
		for x in range(generatedTiles.size()):
			if generatedTiles[x][generatedTiles[x].size() - 1].tile == tiles.DOOR_CLOSED:
				generatedTiles[x][generatedTiles[x].size() - 1].tile = tiles[_fillEdges]
		for y in range(1, generatedTiles[0].size() - 1):
			if generatedTiles[0][y].tile == tiles.DOOR_CLOSED:
				generatedTiles[0][y].tile = tiles[_fillEdges]
		for y in range(1, generatedTiles[0].size() - 1):
			if generatedTiles[generatedTiles.size() - 1][y].tile == tiles.DOOR_CLOSED:
				generatedTiles[generatedTiles.size() - 1][y].tile = tiles[_fillEdges]


#######################################
### Input node processing functions ###
#######################################

func addInputs(_name, _path) -> void:
	var dir = DirAccess.open(_path)
	var inputFilenames = []
	if dir:
		dir.list_dir_begin()
		var fileName = dir.get_next()
		while fileName != "":
			if not dir.current_is_dir() and fileName.get_extension().matchn("tscn"):
				inputFilenames.append(fileName)
			fileName = dir.get_next()
	for fileName in inputFilenames:
		$Inputs.add_child(load("res://Level Generation/WFC Generation/{name}/Inputs/{fileName}".format({ name = _name, fileName = fileName })).instance())

func removeInputs() -> void:
	for _inputNode in $Inputs.get_children():
		_inputNode.clear()
		_inputNode.free()


########################
### Random functions ###
########################

func getRandomLowestEntropyEdgeTile() -> Object:
	var _lowestEntropyEdgeTiles = []
	var _lowestEntropyEdgeTileSize = edgeTiles.front().matches.size() + entropyVariation
	for _edgeTile in edgeTiles:
		if _edgeTile.matches.size() <= _lowestEntropyEdgeTileSize and helperFunctions.checkIfArrayOfClassesHasValue(_lowestEntropyEdgeTiles, "position", _edgeTile.position) == -1:
			_lowestEntropyEdgeTiles.append(_edgeTile)
		else:
			break
	return _lowestEntropyEdgeTiles[randi() % _lowestEntropyEdgeTiles.size()]

func getRandomPattern() -> PackedInt32Array:
	if allInputs.size() != 0:
		return allInputs[randi() % allInputs.size()]
	push_error("No valid inputs!")
	return PackedInt32Array()
