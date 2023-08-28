extends TileMap
class_name WaveFunctionCollapse

@onready var inputCreationFunctions = preload("res://Objects/WFCInputCreationFunctions.gd").new()
@onready var patternProcessingFunctions = preload("res://Objects/WFCPatternProcessingFunctions.gd").new()
@onready var helperFunctions = preload("res://Objects/WFCHelperFunctions.gd").new()
@onready var edgeTile = preload("res://Objects/EdgeTile.gd")

enum tiles { 
	EMPTY,
	CORRIDOR_DUNGEON,
	WALL_DUNGEON,
	FLOOR_DUNGEON,
	SIDEWALK,
	DOWN_STAIR_DUNGEON,
	UP_STAIR_DUNGEON,
	DOOR_CLOSED,
	DOOR_OPEN,
	GRASS_SIMPLE,
	SEA,
	SAND,
	SOIL,
	WALL_SAND,
	WALL_BRICK_SAND,
	FLOOR_SAND,
	DOWN_STAIR_SAND,
	UP_STAIR_SAND,
	CORRIDOR_SAND,
	WALL_BOARD,
	WALL_BRICK_LARGE,
	BOOKCASE1,
	BOOKCASE2,
	BOOKCASE3,
	GRASS,
	GRASS_TREE,
	GRASS_DARK,
	GRASS_LIGHT,
	GRASS_YELLOW,
	REPLACEABLE1,
	REPLACEABLE2,
	REPLACEABLE3,
	REPLACEABLE4,
	REPLACEABLE5,
	ROAD_DUNGEON,
	VILLAGE_WALL_HORIZONTAL,
	VILLAGE_WALL_CORNER,
	VILLAGE_WALL_VERTICAL,
	ROAD_GRASS,
	WALL_BRICK_SMALL,
	FLOOR_BRICK_SMALL,
	VILLAGE_WALL_HALFWALL,
	FLOOR_WOOD_BRICK,
	GRASS_DEAD_TREE,
	WALL_STONE_BRICK,
	WALL_WOOD_PLANK,
	FLOOR_STONE_BRICK
}

var gridSize = Vector2(60,28)
var entropyVariation = 0

var allInputs
var generatedTiles = {}
var edgeTiles = []
var nonLegibleTiles = []

func sortToLowestEntropy(a, b) -> bool:
	return a.matches.size() < b.matches.size()

func generateMap(_entropyVariation = null) -> void:
	if _entropyVariation != null:
		entropyVariation = _entropyVariation
	
	assignAllInputs()
	placeCornerPatterns()
	
	set_physics_process(true)

func _ready():
	set_physics_process(false)

func _physics_process(_delta):
	if !edgeTiles.is_empty():
		var _tile = getRandomLowestEntropyEdgeTile()
		if _tile == null:
			return
		if !isTileLegible(_tile):
			edgeTiles.erase(_tile)
			nonLegibleTiles.append(_tile.position)
		
		getMatchesForEdgeTiles()
		edgeTiles.sort_custom(sortToLowestEntropy)
		
		$CanvasLayer/EdgeTilesDraw.resetEdgeTilesDraw()
		$CanvasLayer/EdgeTilesDraw.addAllEdgeTiles(edgeTiles)
	else:
		trimGenerationEdges()
		set_physics_process(false)

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

func resetGeneration() -> void:
	allInputs.clear()
	generatedTiles.clear()
	edgeTiles.clear()
	nonLegibleTiles.clear()



####################################
### Edge tile updating functions ###
####################################

func doesTileHaveLegibleInputs(_tile, _randomMatch) -> Dictionary:
	### Tiles to be changed
	var _tilesToBeChanged = addToTilesToBeChanged(_tile.position, _randomMatch, {})
	
	### Tiles to be checked for edgetiles
	var _tilesToBeCheckedForEdgeTiles = addToTilesToBeCheckedForEdgeTiles(_tile.position, {})
	
	### Edgetiles to be looped through
	var _testEdgeTiles = getEdgeTilesForTile(_tile.position, [], _tilesToBeChanged)

	### Check what edgetiles are legible
	while true:
		var _tiles = checkForLegibleEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles, _testEdgeTiles)
		if _tiles == null:
			break
		else:
			_tilesToBeChanged = _tiles.tilesToBeChanged
			_tilesToBeCheckedForEdgeTiles = _tiles.tilesToBeCheckedForEdgeTiles
			_testEdgeTiles = _tiles.testEdgeTiles
	
	### Check what the new edgetiles will be
	var _newTestEdgeTiles = getNewEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles)
	
	return {
		"tiles": _tilesToBeChanged,
		"edgeTiles": {
			"add": _newTestEdgeTiles.add,
			"remove": _newTestEdgeTiles.remove
		}
	}

func getEdgeTilesForTile(_tile, _currentEdgeTiles, _tilesToBeChanged) -> Array:
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
				!(
					x < 2 or
					y < 2 or
					x > gridSize.x - 3 or
					y > gridSize.y - 3
				)
			):
				var _newEdgeTile = edgeTile.edgeTile.new()
				_newEdgeTile.setValues(Vector2(x,y))
				_newEdgeTiles.append(_newEdgeTile)
			elif _newEdgeTileIndex != -1:
				_newEdgeTiles.remove_at(_newEdgeTileIndex)
	return _newEdgeTiles

func checkForLegibleEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles, _testEdgeTiles):
	var _newTilesToBeChanged = _tilesToBeChanged.duplicate(true)
	var _newTilesToBeCheckedForEdgeTiles = _tilesToBeCheckedForEdgeTiles.duplicate(true)
	var _newTestEdgeTiles = _testEdgeTiles.duplicate(true)
	var _singleMatchFound = false
	
	for _edgeTile in _testEdgeTiles:
		var _partialPattern = patternProcessingFunctions.getPartialPatternForTile(_edgeTile.position, generatedTiles, _tilesToBeChanged)
		var _matches = patternProcessingFunctions.findAllPartialPatternMatches(_partialPattern, allInputs)
		if typeof(_matches) == TYPE_BOOL:
			continue
		elif _matches.size() == 1:
			_singleMatchFound = true
			_newTilesToBeChanged = addToTilesToBeChanged(_edgeTile.position, _matches[0], _newTilesToBeChanged)
			_newTilesToBeCheckedForEdgeTiles = addToTilesToBeCheckedForEdgeTiles(_edgeTile.position, _newTilesToBeCheckedForEdgeTiles)
			_newTestEdgeTiles = getEdgeTilesForTile(_edgeTile.position, _newTestEdgeTiles, _newTilesToBeChanged)
	
	if _singleMatchFound:
		return {
			"tilesToBeChanged": _newTilesToBeChanged,
			"tilesToBeCheckedForEdgeTiles": _newTilesToBeCheckedForEdgeTiles,
			"testEdgeTiles": _newTestEdgeTiles
		}
	else:
		return null

func isPatternFull(_tile, _tilesToBeChanged) -> bool:
	var _partialPattern = patternProcessingFunctions.getPartialPatternForTile(_tile, generatedTiles)
	var _adjacentTilesDirections = PackedVector2Array([
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
	for _adjacentTileDirection in _adjacentTilesDirections:
		var _adjacentTile = Vector2(_tile.x + _adjacentTileDirection.x, _tile.y + _adjacentTileDirection.y)
		if (
			(
				_tilesToBeChanged.has(_adjacentTile)
			) or
			(
				!_tilesToBeChanged.has(_adjacentTile) and
				generatedTiles.has(_adjacentTile)
			)
		):
			_tileCount += 1
		else:
			return false
	return _tileCount == 9

func getNewEdgeTiles(_tilesToBeChanged, _tilesToBeCheckedForEdgeTiles) -> Dictionary:
	### New edgetiles
	var _newAddTestEdgeTiles = []
	var _newRemoveTestEdgeTiles = []
	
	### Get legible edgetiles in the area
	for _tile in _tilesToBeCheckedForEdgeTiles:
		var _edgeTile = _tilesToBeCheckedForEdgeTiles[_tile]
		var _addEdgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(_newAddTestEdgeTiles, "position", _edgeTile.position)
		var _removeEdgeTileIndex = helperFunctions.checkIfArrayOfClassesHasValue(_newRemoveTestEdgeTiles, "position", _edgeTile.position)
		if (
			helperFunctions.checkIfTileExists(_edgeTile.position, _tilesToBeChanged, generatedTiles) and
			!nonLegibleTiles.has(_edgeTile.position) and
			_addEdgeTileIndex == -1 and
			!isPatternFull(_edgeTile.position, _tilesToBeChanged) and
			!(
				_edgeTile.position.x < 2 or
				_edgeTile.position.y < 2 or
				_edgeTile.position.x > gridSize.x - 3 or
				_edgeTile.position.y > gridSize.y - 3
			)
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

func addToTilesToBeChanged(_tile, _pattern, _currenTestTiles = {}) -> Dictionary:
	var _testTiles = _currenTestTiles.duplicate(true)
	var _i = 0
	for _x in range(-1, 2):
		for _y in range(-1, 2):
			var _checkedTile = Vector2(_tile.x + _x, _tile.y + _y)
			if !_testTiles.has(_checkedTile):
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

func getMatchesForEdgeTiles() -> void:
	var _newEdgeTiles = []
	for _edgeTile in edgeTiles:
		if _edgeTile.matches == null:
			var _matches = patternProcessingFunctions.findAllPartialPatternMatches(patternProcessingFunctions.getPartialPatternForTile(_edgeTile.position, generatedTiles), allInputs)
			if typeof(_matches) == TYPE_BOOL and _matches == false:
				nonLegibleTiles.append(_edgeTile.position)
			else:
				_edgeTile.matches = _matches
				_newEdgeTiles.append(_edgeTile)
		else:
			_newEdgeTiles.append(_edgeTile)
	edgeTiles = _newEdgeTiles



##################################
### Pattern matching functions ###
##################################


################################
### Tile placement functions ###
###############################

func drawPattern(_tile, _pattern):
	if typeof(_pattern) == TYPE_BOOL:
		return
	var _index = 0
	for x in range(3):
		for y in range(3):
			var _drawnTile = Vector2(_tile.x + (x - 1), _tile.y + (y - 1))
			set_cell(0, _drawnTile, _pattern[_index], Vector2i(0, 0))
			generatedTiles[_drawnTile] = _pattern[_index]
			_index += 1


#######################################
### Input node processing functions ###
#######################################

func assignAllInputs() -> void:
	var _inputsInArray = []
	var _inputs = []
	
	for _inputNode in $"../Inputs".get_children():
		_inputNode.create()
		var _input = inputCreationFunctions.createInput(_inputNode)
		for _i in range(4):
			var _newInputPatterns = inputCreationFunctions.getInputPatterns(_input, _inputsInArray)
			if !_newInputPatterns.is_empty():
				_inputsInArray.append(_newInputPatterns)
			_input = inputCreationFunctions.turnInput(_input)
	for _inputArray in _inputsInArray:
		for _input in _inputArray:
			_inputs.append(inputCreationFunctions.transformInputToPackedInt32Array(_input))
	
	allInputs = _inputs

func addInputs(_name, _path):
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

func removeInputs():
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

func placeCornerPatterns() -> void:
	drawPattern(Vector2(2, 2), getRandomPattern())
	
	var _edgeTiles = []
	var _newEdgeTile1 = edgeTile.edgeTile.new()
	var _newEdgeTile2 = edgeTile.edgeTile.new()
	_newEdgeTile1.setValues(Vector2(1,2))
	_newEdgeTile2.setValues(Vector2(2,1))
	_edgeTiles.append(_newEdgeTile1)
	_edgeTiles.append(_newEdgeTile2)
	
	for _edgeTile in _edgeTiles:
		var _matches = patternProcessingFunctions.findAllPartialPatternMatches(patternProcessingFunctions.getPartialPatternForTile(_edgeTile.position, generatedTiles), allInputs)
		if typeof(_matches) == TYPE_BOOL:
			continue
		_edgeTile.setValues(_edgeTile.position, _matches)
		edgeTiles.append(_edgeTile)

func trimGenerationEdges() -> void:
	var _trimmedGeneratedTiles = []
	var _generatedTilesCopy = generatedTiles.duplicate(true)
	for x in range(gridSize.x - 8):
		_trimmedGeneratedTiles.append([])
		for y in range(gridSize.y - 8):
			_trimmedGeneratedTiles[x].append(_generatedTilesCopy[x + 4][y + 4].tile)
	for x in _trimmedGeneratedTiles.size():
		for y in _trimmedGeneratedTiles[x].size():
			generatedTiles[x][y].tile = _trimmedGeneratedTiles[x][y]

func fillEmptyGenerationTiles(_tile, _fillEdges = null) -> void:
	for x in range(generatedTiles.size()):
		for y in range(generatedTiles[x].size()):
			if generatedTiles[x][y].tile == -1:
				generatedTiles[x][y].tile = tiles[_tile]
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
