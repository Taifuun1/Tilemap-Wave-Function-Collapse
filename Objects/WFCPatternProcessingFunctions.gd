
func createNewPattern() -> PackedInt32Array:
	var _newInputPattern = PackedInt32Array()
	for i in range(9):
		_newInputPattern.append(-1)
	return _newInputPattern

func getPartialPatternForTile(_tile, _generatedTiles, _testTiles = null) -> PackedInt32Array:
	var _partialPattern = createNewPattern()
	var _i = 0
	for _x in range(-1, 2):
		for _y in range(-1, 2):
			var _checkedTile = Vector2(_tile.x + _x, _tile.y + _y).floor()
			if _testTiles != null and _testTiles.has(Vector2(_x, _y)):
				_partialPattern[_i] = _testTiles[Vector2(_x, _y)]
			elif _generatedTiles.has(_checkedTile):
				_partialPattern[_i] = _generatedTiles[_checkedTile]
			else:
				_partialPattern[_i] = -1
			_i += 1
	return _partialPattern

func findAllPartialPatternMatches(_partialPattern, _allInputs):
	var _matches = []
	for _inputPattern in _allInputs:
		var _match = isPartialPatternAMatch(_partialPattern, _inputPattern)
		if _match and !checkMatchesDoesntHavePattern(_partialPattern, _matches):
			_matches.append(_inputPattern)
	if _matches.is_empty():
		return false
	return _matches

func isPartialPatternAMatch(_partialPattern: PackedInt32Array, _inputPattern: PackedInt32Array) -> bool:
	for i in _partialPattern.size():
			if _partialPattern[i] != -1 and _partialPattern[i] != _inputPattern[i]:
				return false
	return true

func checkMatchesDoesntHavePattern(_newInputPattern, _array) -> bool:
	for _inputPattern in _array:
		if checkIfPatternsAreEqual(_newInputPattern, _inputPattern):
			return true
	return false

func checkIfPatternsAreEqual(_newInputPattern: PackedInt32Array, _inputPattern: PackedInt32Array) -> bool:
	for i in _newInputPattern.size():
			if _newInputPattern[i] != _inputPattern[i]:
				return false
	return true
